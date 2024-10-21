# synthesis of the design  
This part is about the synthesis of the design,  
**FIRST: ** the ram of **FETCH** and **MEMORY** stages are changed, this happened because the synthesiser doesn't recognize the older codes tobe synthesisable, so it maps everything to the 
ground and displays 0 usage of logic.  
**SECOND:** new modules are introduced *byteAdressable_32ram* and *byteAdressable_ram* the latter is used to buold the ram module that is used for synthesis.aparantly quartus synthesiser 
uses the input and output to determin the used ram module, it has only 1 or 2 port rams but mine has 4 ports and it is byte adressable. so it was not recognized and not synthesised,
the work around is to use a 8xN memory to generate a larger module,
