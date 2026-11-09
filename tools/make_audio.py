import numpy as np, wave
from pathlib import Path
root=Path(__file__).resolve().parents[1] / 'assets' / 'audio'; sr=24000
root.mkdir(parents=True, exist_ok=True)

def save(name,a):
    a=np.clip(a,-.96,.96)
    with wave.open(str(root/(name+'.wav')),'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(sr); w.writeframes((a*32767).astype('<i2').tobytes())
def bell(d,f,amp=.3):
    t=np.arange(int(sr*d))/sr; a=(np.sin(2*np.pi*f*t)+.28*np.sin(2*np.pi*f*2.003*t)+.09*np.sin(2*np.pi*f*3.97*t))*np.exp(-t*2.4)*np.minimum(t/.012,1)*amp
    return np.column_stack((a,a*.94))
save('turn',bell(.8,220,.18));save('align',bell(2.3,659.255,.25)+bell(2.3,987.77,.10));save('step',bell(.18,164.81,.065))
a=np.zeros((sr*7,2))
for i,f in enumerate([261.626,329.628,391.995,523.251,659.255]):
    b=bell(3.5,f,.16); start=int(i*.45*sr); a[start:start+len(b)]+=b
save('win',a)
t=np.arange(sr*24)/sr;a=np.zeros((len(t),2))
# Integer cycles make the restrained pad seamless over its 24-second loop.
for j,f in enumerate([130.833333,196,261.666667,329.666667]):
    for ch in range(2):
        a[:,ch]+=.035*np.sin(2*np.pi*f*t+ch*.4+j)*(.72+.28*np.sin(2*np.pi*t/24+j+ch*.25))
save('ambience',a)
