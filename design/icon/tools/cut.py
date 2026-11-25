import sys, numpy as np, cv2
from PIL import Image
from scipy import ndimage as ndi
src=np.asarray(Image.open('src.webp').convert('RGB'))
L=cv2.cvtColor(src,cv2.COLOR_RGB2GRAY).astype(np.float32)
T=float(sys.argv[1]) if len(sys.argv)>1 else 40
m=(cv2.GaussianBlur(L,(0,0),1.2)>T)
m=ndi.binary_closing(m,iterations=3)
m=ndi.binary_fill_holes(m)
lab,n=ndi.label(m); sizes=ndi.sum(m,lab,range(1,n+1))
keep=[i+1 for i,s in enumerate(sizes) if s>2000]
print('components',n,'kept',len(keep),sorted(sizes)[-5:])
m=np.isin(lab,keep)
m=ndi.binary_opening(m,iterations=1)
Image.fromarray((m*255).astype(np.uint8)).save('mask.png')
ys,xs=np.where(m); print('bbox',xs.min(),ys.min(),xs.max(),ys.max())
