   DAEA  0646  dect R6             * parameters onto DATA stack         
   DAEC  C584  mov  R4,*R6                 
   DAEE  0204  li   R4,>2000              
   DAF2  0646  dect R6                    
   DAF4  C584  mov  R4,*R6                 
   DAF6  0204  li   R4,>1ffe              
   DAFA  0646  dect R6                    
   DAFC  C584  mov  R4,*R6              
   DAFE  0204  li   R4,>0101              
   DB02  06A0  bl   @>dac0          * CALL FILLW 

  *************** sieve program *****************
   DB06  04C0  clr  R0                     (14)
   DB08  04C3  clr  R3                     (14)
   DB0A  0205  li   R5,>2000               (20)
   DB0E  0646  dect R6                     (14)
   DB10  C584  mov  R4,*R6                 (30)
   DB12  0204  li   R4,>0000               (20)
>  DB16  0646  dect R6                    
   DB18  C584  mov  R4,*R6         * loop index on DATA stack        
   DB1A  0204  li   R4,>1ffe              
   DB1E  0647  dect R7             * FOR loop push TOS cache onto return stack 
   DB20  C5C4  mov  R4,*R7                
   DB22  C136  mov  *R6+,R4        * refill TOS cache from DATA stack        
   DB24  90F5  cb   *R5+,R3               
   DB26  130E  jeq  >db44                 
   DB28  C040  mov  R0,R1                 
   DB2A  0A11  sla  R1,1                  
   DB2C  0221  ai   R1,>0003              
   DB30  C080  mov  R0,R2        
   DB32  A081  a    R1,R2                  (18)
   DB34  0282  ci   R2,>1ffe               (22)
   DB38  1504  jgt  >db42                  (12)
   DB3A  D883  movb R3,@>2000(R2)          (38)
   DB3E  A081  a    R1,R2                  (18)
>  DB40  10F9  jmp  >db34                 
   DB42  0584  inc  R4                    
   DB44  0580  inc  R0                    
   DB46  0617  dec  *R7           * NEXT loop        
   DB48  18ED  joc  >db24             
   DB4A  05C7  inct R7            * pop index from return stack         
   DB4C  045A  b    *R10          * return to Forth  