       AORG >A000
* assumes startup from Editor/Assembler

  DEF START
  REF VDPWA,VDPWD
  
* make it work as EA5 if desired
  B @START

START
  lwpi >8300
  li r1,>8320
  li r0,l140
! mov *R0+,*R1+
  ci R1,>8400
  jne -!

* call clear
  li r0,>0040     * write address >0000
  movb r0,@VDPWA
  swpb r0
  movb r0,@VDPWA
  
  li r1,>2000
  li r2,768
lp1
  movb r1,@VDPWD
  dec r2
  jne lp1
  
* call magnify(2)
  li r0,>c181     * write VDP register 1 with >C2 (16k,enable, no int, double-size sprites)
  movb r0,@VDPWA
  swpb r0
  movb r0,@VDPWA
  
* call sprite(#1,42,2,1,1)
  li r0,>0186     * vdp register 6 to >01 (sprite descriptor table to >0800)
  movb r0,@VDPWA
  swpb r0
  movb r0,@VDPWA

  li r0,>0043     * write address >0300
  movb r0,@VDPWA
  swpb r0
  movb r0,@VDPWA
 
  li r0,>002A     * 1,1 (minus 1) and 42
  movb r0,@VDPWD
  nop
  movb r0,@VDPWD
  swpb r0
  movb r0,@VDPWD
  
  li r0,>01d0     * color 2 (-1) and list terminator
  movb r0,@VDPWD
  swpb r0
  movb r0,@VDPWD
  
* cnt=100
  li r5,10000
  
  li r0,>0143     * write address >0301 (X pos)
  li r6,>4310
  li r1,>0043     * write address >0300 (Y pos)
  li r7,>4300
  clr r4
  B @>8320
l140
  li r3,>0100

* for x=1 to 240 (minus 1 for asm)
xlp1

* call locate(#1,1,x)
  movb r0,@VDPWA
  nop
  movb r6,@VDPWA
  nop
  movb r3,@VDPWD  
  
* next x
  ai r3,>0100
  ci r3,>ef00
  jne xlp1

  movb r0,@VDPWA
  nop
  movb r6,@VDPWA
  nop
  movb r3,@VDPWD  
  jmp opt1
  
* for y=1 to 176
ylp1

* call locate(#1,y,240)
  movb r1,@VDPWA
  nop
  movb r7,@VDPWA
  nop
  movb r4,@VDPWD
  
* next y
opt1
  ai r4,>0100
  ci r4,>af00
  jne ylp1

  movb r1,@VDPWA
  nop
  movb r7,@VDPWA
  nop
  movb r4,@VDPWD
  nop
  
* for x=240 to 1 step -1
xlp2

* call locate(#1,176,x)
  movb r0,@VDPWA
  nop
  movb r6,@VDPWA
  nop
  movb r3,@VDPWD  
  
* next x
  ai r3,>ff00
  jne xlp2

  movb r0,@VDPWA
  nop
  movb r6,@VDPWA
  nop
  movb r3,@VDPWD  
  jmp opt2
  
* for y=176 to 1 step -1
  
ylp2
* call locate(#1,y,1)
  movb r1,@VDPWA
  nop
  movb r7,@VDPWA
  nop
  movb r4,@VDPWD
  
* next y
opt2
  ai r4,>ff00
  jne ylp2

  movb r1,@VDPWA
  nop
  movb r7,@VDPWA
  nop
  movb r4,@VDPWD
  
* cnt=cnt-1
  dec r5
  jne l140
  
* end
  clr  @>83C4
  blwp @>0000
  
  end
 