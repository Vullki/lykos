import numpy as np, cv2
from PIL import Image
src=np.asarray(Image.open('src.webp').convert('RGB')).astype(np.float32)
m=np.asarray(Image.open('mask.png')).astype(np.float32)/255
# anti-aliased alpha: erode 1px so no dark rim, then soften
a=cv2.erode(m,np.ones((3,3),np.uint8),iterations=1)
a=np.clip(cv2.GaussianBlur(a,(0,0),0.9),0,1)
A=(a*255).round().astype(np.uint8)
# Any: the artwork itself, opaque RGB
Image.fromarray(src.astype(np.uint8)).save('lykos-any.png',optimize=True)
# Dark: brushed letters on transparency
dark=np.dstack([src.astype(np.uint8),A]); Image.fromarray(dark,'RGBA').save('lykos-dark.png',optimize=True)
# Tinted: grayscale, lifted to a bright range so the system tint reads strongly
g=cv2.cvtColor(src.astype(np.uint8),cv2.COLOR_RGB2GRAY).astype(np.float32)
inside=a>0.5; lo,hi=np.percentile(g[inside],[2,98])
gt=np.clip((g-lo)/(hi-lo),0,1)*95+160
gt=gt.round().astype(np.uint8)
Image.fromarray(np.dstack([gt,gt,gt,A]),'RGBA').save('lykos-tinted.png',optimize=True)
# Mark: tight crop, centred on a square canvas
ys,xs=np.where(A>0); x0,y0,x1,y1=xs.min(),ys.min(),xs.max()+1,ys.max()+1
crop=Image.fromarray(dark,'RGBA').crop((x0,y0,x1,y1)); w,h=crop.size; s=int(max(w,h)*1.04)
sq=Image.new('RGBA',(s,s),(0,0,0,0)); sq.paste(crop,((s-w)//2,(s-h)//2))
sq.resize((1024,1024),Image.LANCZOS).save('lykos-mark.png',optimize=True)
sq.resize((480,480),Image.LANCZOS).save('lykos-mark@3x.png',optimize=True)
# Previews: dark on black, tinted on black with a tint, all at phone sizes
prev=Image.new('RGB',(1500,560),(40,40,40))
def mask_rounded(im,size):
    im=im.resize((size,size),Image.LANCZOS).convert('RGBA'); r=int(size*0.2237)
    mk=Image.new('L',(size,size),0)
    from PIL import ImageDraw; ImageDraw.Draw(mk).rounded_rectangle((0,0,size-1,size-1),r,fill=255)
    out=Image.new('RGBA',(size,size),(0,0,0,0)); out.paste(im,(0,0),mk); return out
anyi=Image.open('lykos-any.png'); darki=Image.open('lykos-dark.png')
bd=Image.new('RGBA',(1024,1024),(0,0,0,255)); bd.alpha_composite(darki)
tint=np.asarray(Image.open('lykos-tinted.png')).astype(np.float32)
tc=np.zeros((1024,1024,3),np.float32); al=tint[...,3:4]/255
tc=tc*(1-al)+ (tint[...,:3]/255*np.array([120,200,255]))*al
ti=Image.fromarray(tc.astype(np.uint8)).convert('RGBA')
x=20
for im in (anyi,bd,ti):
    for sz in (360,180,87,58):
        prev.paste(mask_rounded(im,sz),(x,100),mask_rounded(im,sz)); x+=sz+14
    x+=20
prev.save('preview.png')
print('mark bbox',x0,y0,x1,y1)
