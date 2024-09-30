test of axi4 stream subset converter. Trying to packetize samples from ADC and send to DMA. 
ADC SPI core does not generate TLAST signal which DMA needs. Trying to generate TLAST with subset converter as used here: 
https://community.element14.com/technologies/fpga-group/b/blog/posts/use-the-zynq-xadc-with-dma-part-1-bare-metal
