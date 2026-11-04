
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5511d0: 0b 00                        	or	eax, dword ptr [eax]
  5511d2: 00 ff                        	add	bh, bh
  5511d4: 15 1c 59 c2 00               	adc	eax, 0xc2591c
  5511d9: f6 05 28 1e d7 00 03         	test	byte ptr [0xd71e28], 0x3
  5511e0: 74 45                        	je	0x551227 <.text+0x150227>
  5511e2: ff 15 04 59 c2 00            	call	dword ptr [0xc25904]
  5511e8: 68 f0 e1 c2 00               	push	0xc2e1f0
  5511ed: b9 60 74 10 01               	mov	ecx, 0x1107460
  5511f2: e8 e9 a4 00 00               	call	0x55b6e0 <.text+0x15a6e0>
  5511f7: 8b f0                        	mov	esi, eax
  5511f9: 68 c0 d5 c2 00               	push	0xc2d5c0
  5511fe: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  551203: e8 18 c9 fe ff               	call	0x53db20 <.text+0x13cb20>
  551208: 8b 53 08                     	mov	edx, dword ptr [ebx + 0x8]
  55120b: 83 c4 f4                     	add	esp, -0xc
  55120e: 89 14 24                     	mov	dword ptr [esp], edx
  551211: 89 74 24 04                  	mov	dword ptr [esp + 0x4], esi
  551215: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  551219: e8 e2 1e ff ff               	call	0x543100 <.text+0x142100>
  55121e: 83 c4 0c                     	add	esp, 0xc
  551221: ff 15 08 59 c2 00            	call	dword ptr [0xc25908]
  551227: ff 15 08 59 c2 00            	call	dword ptr [0xc25908]
  55122d: eb 77                        	jmp	0x5512a6 <.text+0x1502a6>
  55122f: 68 e2 0b 00 00               	push	0xbe2
  551234: ff 15 18 59 c2 00            	call	dword ptr [0xc25918]
  55123a: 0f b6 05 58 0e d7 00         	movzx	eax, byte ptr [0xd70e58]
  551241: 85 c0                        	test	eax, eax
  551243: 74 0e                        	je	0x551253 <.text+0x150253>
  551245: 50                           	push	eax
  551246: c7 04 24 00 00 80 3f         	mov	dword ptr [esp], 0x3f800000
  55124d: ff 15 d4 59 c2 00            	call	dword ptr [0xc259d4]
  551253: 6a 00                        	push	0x0
  551255: ff 15 d4 58 c2 00            	call	dword ptr [0xc258d4]
  55125b: 8b 45 c0                     	mov	eax, dword ptr [ebp - 0x40]
  55125e: 83 c4 f0                     	add	esp, -0x10
  551261: c7 04 24 00 00 80 3f         	mov	dword ptr [esp], 0x3f800000
  551268: c7 44 24 04 00 00 80 3f      	mov	dword ptr [esp + 0x4], 0x3f800000
  551270: 89 44 24 0c                  	mov	dword ptr [esp + 0xc], eax
  551274: c7 44 24 08 00 00 80 3f      	mov	dword ptr [esp + 0x8], 0x3f800000
  55127c: ff 15 70 59 c2 00            	call	dword ptr [0xc25970]
