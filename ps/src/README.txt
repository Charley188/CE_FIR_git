首次使用新bit/XSA更新Vitis平台。保留src/coeff目录。
你手动把MATLAB导出的300行h_re.mem和h_im.mem放入src/coeff。
Vitis Classic: Clean -> Build -> Run。两份MEM在编译时嵌入ELF。
加载第一路300tap复数FIR；第二路仍直通。详细操作见../../docs/ONLINE.md。
