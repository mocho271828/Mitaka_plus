
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5ec920: a1 3c 1b 08 01               	mov	eax, dword ptr [0x1081b3c]
  5ec925: c3                           	ret
  5ec926: 8d 76 00                     	lea	esi, [esi]
  5ec929: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5ec930: e8 8b 4b f2 ff               	call	0x5114c0 <.text+0x1104c0>
  5ec935: c3                           	ret
  5ec936: 8d 76 00                     	lea	esi, [esi]
  5ec939: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5ec940: 56                           	push	esi
  5ec941: 8b f1                        	mov	esi, ecx
  5ec943: e8 78 4b f2 ff               	call	0x5114c0 <.text+0x1104c0>
  5ec948: 0f b6 c0                     	movzx	eax, al
  5ec94b: ba 01 00 00 00               	mov	edx, 0x1
  5ec950: 33 c9                        	xor	ecx, ecx
  5ec952: 85 c0                        	test	eax, eax
  5ec954: 0f 44 ca                     	cmove	ecx, edx
  5ec957: 51                           	push	ecx
  5ec958: 8b ce                        	mov	ecx, esi
  5ec95a: e8 11 00 00 00               	call	0x5ec970 <.text+0x1eb970>
  5ec95f: 5e                           	pop	esi
  5ec960: c3                           	ret
  5ec961: 90                           	nop
  5ec962: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  5ec969: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5ec970: 55                           	push	ebp
  5ec971: 8b ec                        	mov	ebp, esp
  5ec973: 6a ff                        	push	-0x1
  5ec975: 68 c0 d8 bf 00               	push	0xbfd8c0
  5ec97a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5ec980: 50                           	push	eax
  5ec981: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5ec988: 83 ec 78                     	sub	esp, 0x78
  5ec98b: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  5ec98e: 89 5d e8                     	mov	dword ptr [ebp - 0x18], ebx
  5ec991: 89 7d e0                     	mov	dword ptr [ebp - 0x20], edi
  5ec994: 89 75 e4                     	mov	dword ptr [ebp - 0x1c], esi
  5ec997: a1 10 53 d8 00               	mov	eax, dword ptr [0xd85310]
  5ec99c: 89 4d bc                     	mov	dword ptr [ebp - 0x44], ecx
  5ec99f: 89 45 ec                     	mov	dword ptr [ebp - 0x14], eax
  5ec9a2: e8 19 4b f2 ff               	call	0x5114c0 <.text+0x1104c0>
  5ec9a7: 0f b6 55 08                  	movzx	edx, byte ptr [ebp + 0x8]
  5ec9ab: 0f b6 c0                     	movzx	eax, al
  5ec9ae: 3b c2                        	cmp	eax, edx
  5ec9b0: 74 39                        	je	0x5ec9eb <.text+0x1eb9eb>
  5ec9b2: 52                           	push	edx
  5ec9b3: e8 08 87 e9 ff               	call	0x4850c0 <.text+0x840c0>
  5ec9b8: 59                           	pop	ecx
  5ec9b9: e8 02 99 fd ff               	call	0x5c62c0 <.text+0x1c52c0>
  5ec9be: 8b c8                        	mov	ecx, eax
