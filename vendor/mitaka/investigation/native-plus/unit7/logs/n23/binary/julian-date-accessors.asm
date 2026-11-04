
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  59c3a0: 8b 44 24 04                  	mov	eax, dword ptr [esp + 0x4]
  59c3a4: f2 0f 10 00                  	movsd	xmm0, qword ptr [eax]
  59c3a8: f2 0f 11 05 40 bd 10 01      	movsd	qword ptr [0x110bd40], xmm0
  59c3b0: c6 05 48 bd 10 01 01         	mov	byte ptr [0x110bd48], 0x1
  59c3b7: c3                           	ret
  59c3b8: 90                           	nop
  59c3b9: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  59c3c0: 0f b6 05 48 bd 10 01         	movzx	eax, byte ptr [0x110bd48]
  59c3c7: 85 c0                        	test	eax, eax
  59c3c9: 75 01                        	jne	0x59c3cc <.text+0x19b3cc>
  59c3cb: c3                           	ret
  59c3cc: 33 c0                        	xor	eax, eax
  59c3ce: a2 48 bd 10 01               	mov	byte ptr [0x110bd48], al
  59c3d3: 50                           	push	eax
  59c3d4: 68 40 bd 10 01               	push	0x110bd40
  59c3d9: e8 32 fd f7 ff               	call	0x51c110 <.text+0x11b110>
  59c3de: 68 40 bd 10 01               	push	0x110bd40
  59c3e3: e8 98 9d fc ff               	call	0x566180 <.text+0x165180>
  59c3e8: 83 c4 0c                     	add	esp, 0xc
  59c3eb: c3                           	ret
  59c3ec: 8d 74 26 00                  	lea	esi, [esi + eiz]
  59c3f0: dd 05 40 bd 10 01            	fld	qword ptr [0x110bd40]
  59c3f6: c3                           	ret
  59c3f7: 8b f6                        	mov	esi, esi
  59c3f9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
