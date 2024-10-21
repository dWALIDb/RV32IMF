#synthesis of the design
This part is about the synthesis of the design,
**FIRST: ** the ram of **FETCH** and **MEMORY** stages are changed, this happened because the synthesiser doesn't recognize the older codes tobe synthesisable, so it maps everything to the 
ground and displays 0 usage of logic.  
**SECOND:** new modules are introduced *byteAdressable_32ram* and *byteAdressable_ram* the latter is used to buold the ram module that is used for synthesis.
