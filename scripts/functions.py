import numpy as np

a0 = 0.0080
a1 = -0.1692
a2 = 25.3851
a3 = 14.0941
a4 = -7.0261
a5 = 2.7081
b0 = 0.0005
b1 = -0.0056
b2 = -0.0066
b3 = -0.0375
b4 = 0.0636
b5 = -0.0144
c0 = 0.6766097
c1 = 2.00564e-2
c2 = 1.104259e-4
c3 = -6.9698e-7
c4 = 1.0031e-9
d1 = 3.426e-2
d2 = 4.464e-4
d3 = 4.215e-1
d4 = -3.107e-3
e1 = 2.070e-5
e2 = -6.370e-10
e3 = 3.989e-15
k = 0.0162

def salinity(C,t,p):
    p = 10*p  ##  dBar
    C = 10*C  ##  mS/cm
    #
    t68 = t*1.00024
    ft68 = (t68 - 15)/(1 + k*(t68 - 15))
    R = 0.023302418791070513*C
    rt_lc = c0 + (c1 + (c2 + (c3 + c4*t68)*t68)*t68)*t68
    Rp = 1 + (p*(e1 + e2*p + e3*p*p))/(1 + d1*t68 + d2*t68*t68 + (d3 + d4*t68)*R)
    Rt = R/(Rp*rt_lc)
    Rtx = np.sqrt(Rt)
    SP = a0 + (a1 + (a2 + (a3 + (a4 + a5*Rtx)*Rtx)*Rtx)*Rtx)*Rtx + ft68*(b0 + (b1 + (b2 + (b3 + (b4 + b5*Rtx)*Rtx)*Rtx)*Rtx)*Rtx)
    return SP

##  Convert Degree-Minute to Decimal Degree
def DM2D(x):
    deg = np.trunc(x/100)
    minute = x - 100*deg
    decimal = minute/60
    return deg+decimal

##  Convert radian to degree
def rad2deg(x):
    return x*180/np.pi