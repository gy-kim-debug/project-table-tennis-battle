"""Normalize authorized generated atlases; retain untouched originals.
Dependencies for this build-time utility: Pillow, NumPy, SciPy (not game runtime).
"""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT=Path(__file__).resolve().parents[2]
COUNTS={'idle':4,'swing':6,'miss':4}
FPS={'idle':4,'swing':20,'miss':10}

def build(role):
 source=ROOT/'assets/source/characters'/f'{role}_animation_source.png'
 rgba=np.asarray(Image.open(source).convert('RGBA'))
 labels,_=ndimage.label(rgba[:,:,3]>=128,np.ones((3,3)))
 sizes=np.bincount(labels.ravel())
 objects=[]
 for label,sl in enumerate(ndimage.find_objects(labels),1):
  if sizes[label]<2000: continue
  ys,xs=sl; mask=labels[ys,xs]==label
  row=int(((ys.start+ys.stop)/2)/(rgba.shape[0]/3))
  col=int(((xs.start+xs.stop)/2)/(rgba.shape[1]/6))
  bottom_y=mask.shape[0]-1
  shoe_y,shoe_x=np.where(mask[max(0,bottom_y-12):,:])
  foot_x=(int(shoe_x.min())+int(shoe_x.max()))/2
  objects.append({'row':row,'col':col,'label':label,'box':[xs.start,ys.start,xs.stop,ys.stop],
                  'mask':mask,'rgba':rgba[ys,xs].copy(),'foot_x':foot_x})
 objects.sort(key=lambda obj:(obj['row'],obj['col']))
 assert len(objects)==14, f'{role}: expected 14 major connected sprites, got {len(objects)}'
 assert [(o['row'],o['col']) for o in objects]==[(r,c) for r,count in enumerate(COUNTS.values()) for c in range(count)]
 max_left=max(o['foot_x'] for o in objects)
 max_right=max(o['mask'].shape[1]-1-o['foot_x'] for o in objects)
 max_height=max(o['mask'].shape[0]-1 for o in objects)
 scale=min(120/(max_left+max_right),110/max_height)
 pivot=[int(round(4+max_left*scale)),116]
 # Shared 32-color palette prevents per-frame palette drift; binary alpha removes fringe.
 visible=np.concatenate([o['rgba'][:,:,:3][o['mask']] for o in objects])
 training=Image.fromarray(visible.reshape((-1,1,3)).astype('uint8'),'RGB')
 palette=training.quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
 output=ROOT/'assets/characters'/role; output.mkdir(parents=True,exist_ok=True)
 frames={name:[] for name in COUNTS}; records=[]
 for o in objects:
  name=list(COUNTS)[o['row']]
  pix=o['rgba'];pix[:,:,3]=np.where(o['mask'],255,0).astype('uint8')
  crop=Image.fromarray(pix,'RGBA')
  size=(int(round(crop.width*scale)),int(round(crop.height*scale)))
  small=crop.resize(size,Image.Resampling.NEAREST)
  alpha=small.getchannel('A')
  colored=small.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA')
  colored.putalpha(alpha)
  x=int(round(pivot[0]-o['foot_x']*scale));y=116-(size[1]-1)
  assert x>=0 and y>=0 and x+size[0]<=128 and y+size[1]<=128,(role,o['row'],o['col'],x,y,size)
  frame=Image.new('RGBA',(128,128));frame.alpha_composite(colored,(x,y))
  box=frame.getchannel('A').getbbox()
  assert box is not None and box[3]==117 and box[0]>0 and box[2]<128,box
  frames[name].append(frame)
  records.append({'animation':name,'index':o['col'],'source_rect':o['box'],'opaque_rect':box,
                  'sha256':hashlib.sha256(frame.tobytes()).hexdigest()})
 for name,images in frames.items():
  assert len(images)==COUNTS[name] and len({im.tobytes() for im in images})==len(images)
  sheet=Image.new('RGBA',(128*len(images),128))
  for i,frame in enumerate(images):sheet.alpha_composite(frame,(128*i,0))
  sheet.save(output/f'{role}_{name}.png')
  enlarged=[]
  for frame in images:
   view=Image.new('RGBA',(128,128),(23,33,59,255));view.alpha_composite(frame)
   enlarged.append(view.convert('RGB').resize((256,256),Image.Resampling.NEAREST))
  enlarged[0].save(output/f'{name}_preview.gif',save_all=True,append_images=enlarged[1:],duration=round(1000/FPS[name]),loop=0)
 frames['idle'][0].save(output/f'{role}_base.png')
 # Find the colored paddle center in the contact frame, excluding tiny matte residue.
 contact=np.asarray(frames['swing'][3])
 rgb=contact[:,:,:3].astype('int16')
 if role=='player':mask=(rgb[:,:,0]>110)&(rgb[:,:,0]>rgb[:,:,1]*1.5)&(rgb[:,:,0]>rgb[:,:,2]*1.4)&(contact[:,:,3]>0)
 else:mask=(rgb[:,:,2]>90)&(rgb[:,:,2]>rgb[:,:,0]*1.25)&(rgb[:,:,2]>rgb[:,:,1]*1.15)&(contact[:,:,3]>0)
 cl,n=ndimage.label(mask); areas=np.bincount(cl.ravel());areas[0]=0
 ys,xs=np.where(cl==int(areas.argmax()))
 assert len(xs)>8,(role,'no paddle contact patch')
 contact_point=[int(round(float(xs.mean()))),int(round(float(ys.mean())))]
 manifest={'role':role,'source':str(source.relative_to(ROOT)),'source_size':[rgba.shape[1],rgba.shape[0]],
 'frame_size':[128,128],'pivot':pivot,'contact_frame':3,'contact_point':contact_point,'source_scale':scale,
 'palette_colors':32,'alpha_threshold':128,'animations':{a:{'count':COUNTS[a],'fps':FPS[a],'loop':a=='idle'} for a in COUNTS},
 'validation':'dimensions/binary alpha/full silhouettes/common foot baseline/unique frames verified; visual review pending',
 'frames':records}
 (output/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
 lines=['[gd_resource type="SpriteFrames" load_steps=18 format=3]','']
 for i,name in enumerate(COUNTS,1):lines.append(f'[ext_resource type="Texture2D" path="res://assets/characters/{role}/{role}_{name}.png" id="{i}"]')
 for record in records:
  name=record['animation'];idx=record['index'];rid=list(COUNTS).index(name)+1
  lines.extend(['',f'[sub_resource type="AtlasTexture" id="{name}_{idx}"]',f'atlas = ExtResource("{rid}")',f'region = Rect2({idx*128}, 0, 128, 128)'])
 lines.extend(['','[resource]','animations = ['])
 for name in COUNTS:
  refs=', '.join('{"duration": 1.0, "texture": SubResource("'+name+'_'+str(i)+'")}' for i in range(COUNTS[name]))
  lines.append('{"frames": ['+refs+'], "loop": '+str(name=='idle').lower()+', "name": &"'+name+'", "speed": '+str(float(FPS[name]))+'},')
 lines.append(']')
 (output/'frames.tres').write_text('\n'.join(lines)+'\n')
 previews=[]
 for step in range(12):
  preview=Image.new('RGBA',(384,128),(23,33,59,255))
  for column,name in enumerate(COUNTS):preview.alpha_composite(frames[name][step%COUNTS[name]],(128*column,0))
  previews.append(preview.convert('RGB'))
 previews[0].save(output/'preview.gif',save_all=True,append_images=previews[1:],duration=130,loop=0)
 print(role,'scale',round(scale,4),'pivot',pivot,'contact',contact_point,'14 frames validated')

if __name__=='__main__':
 for character in ['player','enemy']:build(character)
