
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5e9746: 56                           	push	esi
  5e9747: e8 34 4a e3 ff               	call	0x41e180 <.text+0x1d180>
  5e974c: dd 9d 48 ff ff ff            	fstp	qword ptr [ebp - 0xb8]
  5e9752: f2 0f 10 85 48 ff ff ff      	movsd	xmm0, qword ptr [ebp - 0xb8]
  5e975a: f2 0f 10 0d c0 90 fe 00      	movsd	xmm1, qword ptr [0xfe90c0]
  5e9762: 8d 45 c0                     	lea	eax, [ebp - 0x40]
  5e9765: 50                           	push	eax
  5e9766: f2 0f 58 c8                  	addsd	xmm1, xmm0
  5e976a: f2 0f 11 4d c0               	movsd	qword ptr [ebp - 0x40], xmm1
  5e976f: e8 1c d8 e9 ff               	call	0x486f90 <.text+0x85f90>
  5e9774: e9 19 fa ff ff               	jmp	0x5e9192 <.text+0x1e8192>
  5e9779: 90                           	nop
  5e977a: 90                           	nop
  5e977b: 90                           	nop
  5e977c: 90                           	nop
  5e977d: 90                           	nop
  5e977e: 90                           	nop
  5e977f: 90                           	nop
  5e9780: 55                           	push	ebp
  5e9781: 8b ec                        	mov	ebp, esp
  5e9783: 6a ff                        	push	-0x1
  5e9785: 68 20 d7 bf 00               	push	0xbfd720
  5e978a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5e9790: 50                           	push	eax
  5e9791: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5e9798: 81 ec 60 01 00 00            	sub	esp, 0x160
  5e979e: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
