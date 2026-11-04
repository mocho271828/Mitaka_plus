
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  662e00: c4 10                        	les	edx, [eax]
  662e02: 5e                           	pop	esi
  662e03: 5f                           	pop	edi
  662e04: c3                           	ret
  662e05: 8d 74 26 00                  	lea	esi, [esi + eiz]
  662e09: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  662e10: 56                           	push	esi
  662e11: 8b 44 24 08                  	mov	eax, dword ptr [esp + 0x8]
  662e15: e8 1a 00 00 00               	call	0x662e34 <.text+0x261e34>
  662e1a: b8 01 00 00 00               	mov	eax, 0x1
  662e1f: 59                           	pop	ecx
  662e20: c3                           	ret
  662e21: 90                           	nop
  662e22: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  662e29: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  662e30: 8b 44 24 04                  	mov	eax, dword ptr [esp + 0x4]
  662e34: 57                           	push	edi
  662e35: 83 ec 10                     	sub	esp, 0x10
  662e38: 8b f8                        	mov	edi, eax
  662e3a: 57                           	push	edi
  662e3b: e8 a0 da 22 00               	call	0x8908e0 <.text+0x48f8e0>
  662e40: 68 1c 9d c3 00               	push	0xc39d1c
  662e45: 57                           	push	edi
  662e46: e8 85 d3 22 00               	call	0x8901d0 <.text+0x48f1d0>
  662e4b: 68 b8 a0 c3 00               	push	0xc3a0b8
  662e50: 57                           	push	edi
  662e51: e8 7a d3 22 00               	call	0x8901d0 <.text+0x48f1d0>
  662e56: 68 68 9f ca 00               	push	0xca9f68
  662e5b: 57                           	push	edi
  662e5c: e8 6f d3 22 00               	call	0x8901d0 <.text+0x48f1d0>
  662e61: 33 c0                        	xor	eax, eax
  662e63: 50                           	push	eax
  662e64: 50                           	push	eax
  662e65: 57                           	push	edi
  662e66: e8 b5 d4 22 00               	call	0x890320 <.text+0x48f320>
  662e6b: 6a 00                        	push	0x0
  662e6d: 57                           	push	edi
  662e6e: e8 6d d4 22 00               	call	0x8902e0 <.text+0x48f2e0>
  662e73: 6a 00                        	push	0x0
  662e75: 68 3c 9d c3 00               	push	0xc39d3c
  662e7a: 57                           	push	edi
  662e7b: e8 a0 d4 22 00               	call	0x890320 <.text+0x48f320>
  662e80: 68 3c 9d c3 00               	push	0xc39d3c
  662e85: 57                           	push	edi
  662e86: e8 55 d4 22 00               	call	0x8902e0 <.text+0x48f2e0>
  662e8b: 83 c4 44                     	add	esp, 0x44
  662e8e: c7 44 24 04 74 9f ca 00      	mov	dword ptr [esp + 0x4], 0xca9f74
  662e96: 89 3c 24                     	mov	dword ptr [esp], edi
  662e99: 66 0f ef c0                  	pxor	xmm0, xmm0
  662e9d: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  662ea3: e8 58 d7 22 00               	call	0x890600 <.text+0x48f600>
  662ea8: f2 0f 10 05 60 9f ca 00      	movsd	xmm0, qword ptr [0xca9f60]
  662eb0: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  662eb6: 89 3c 24                     	mov	dword ptr [esp], edi
  662eb9: c7 44 24 04 88 9f ca 00      	mov	dword ptr [esp + 0x4], 0xca9f88
  662ec1: e8 3a d7 22 00               	call	0x890600 <.text+0x48f600>
  662ec6: 68 00 0c 66 00               	push	0x660c00
  662ecb: 68 1c 9d c3 00               	push	0xc39d1c
  662ed0: 68 68 9f ca 00               	push	0xca9f68
  662ed5: 68 d8 96 c3 00               	push	0xc396d8
  662eda: 57                           	push	edi
  662edb: e8 40 d5 22 00               	call	0x890420 <.text+0x48f420>
  662ee0: 68 d8 96 c3 00               	push	0xc396d8
  662ee5: 57                           	push	edi
  662ee6: e8 f5 d3 22 00               	call	0x8902e0 <.text+0x48f2e0>
  662eeb: 68 20 0c 66 00               	push	0x660c20
  662ef0: 68 40 9d c3 00               	push	0xc39d40
  662ef5: 57                           	push	edi
  662ef6: e8 d5 d6 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662efb: 68 d0 0c 66 00               	push	0x660cd0
  662f00: 68 44 9d c3 00               	push	0xc39d44
  662f05: 57                           	push	edi
  662f06: e8 c5 d6 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662f0b: 68 d0 0c 66 00               	push	0x660cd0
  662f10: 68 50 9d c3 00               	push	0xc39d50
  662f15: 57                           	push	edi
  662f16: e8 b5 d6 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662f1b: 68 80 0d 66 00               	push	0x660d80
  662f20: 68 58 9d c3 00               	push	0xc39d58
  662f25: 57                           	push	edi
  662f26: e8 a5 d6 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662f2b: 68 a0 0d 66 00               	push	0x660da0
  662f30: 68 60 9d c3 00               	push	0xc39d60
  662f35: 57                           	push	edi
  662f36: e8 95 d6 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662f3b: 68 c0 0d 66 00               	push	0x660dc0
  662f40: 68 6c 9d c3 00               	push	0xc39d6c
  662f45: 57                           	push	edi
  662f46: e8 85 d6 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662f4b: 68 80 11 66 00               	push	0x661180
  662f50: 68 78 9d c3 00               	push	0xc39d78
  662f55: 57                           	push	edi
  662f56: e8 75 d6 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662f5b: 68 c0 11 66 00               	push	0x6611c0
  662f60: 68 84 9d c3 00               	push	0xc39d84
  662f65: 57                           	push	edi
  662f66: e8 65 d6 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662f6b: 83 c4 7c                     	add	esp, 0x7c
  662f6e: 68 f0 11 66 00               	push	0x6611f0
  662f73: 68 90 9d c3 00               	push	0xc39d90
  662f78: 57                           	push	edi
  662f79: e8 52 d6 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662f7e: 68 10 12 66 00               	push	0x661210
  662f83: 68 98 9d c3 00               	push	0xc39d98
  662f88: 57                           	push	edi
  662f89: e8 42 d6 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662f8e: 68 50 12 66 00               	push	0x661250
  662f93: 68 a4 9d c3 00               	push	0xc39da4
  662f98: 57                           	push	edi
  662f99: e8 32 d6 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662f9e: 68 80 12 66 00               	push	0x661280
  662fa3: 68 b0 9d c3 00               	push	0xc39db0
  662fa8: 57                           	push	edi
  662fa9: e8 22 d6 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662fae: 68 a0 12 66 00               	push	0x6612a0
  662fb3: 68 30 ac c3 00               	push	0xc3ac30
  662fb8: 57                           	push	edi
  662fb9: e8 12 d6 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662fbe: 68 e0 12 66 00               	push	0x6612e0
  662fc3: 68 44 ac c3 00               	push	0xc3ac44
  662fc8: 57                           	push	edi
  662fc9: e8 02 d6 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662fce: 68 10 13 66 00               	push	0x661310
  662fd3: 68 58 ac c3 00               	push	0xc3ac58
  662fd8: 57                           	push	edi
  662fd9: e8 f2 d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662fde: 68 30 13 66 00               	push	0x661330
  662fe3: 68 98 9f ca 00               	push	0xca9f98
  662fe8: 57                           	push	edi
  662fe9: e8 e2 d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662fee: 68 70 13 66 00               	push	0x661370
  662ff3: 68 a8 9f ca 00               	push	0xca9fa8
  662ff8: 57                           	push	edi
  662ff9: e8 d2 d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  662ffe: 68 a0 13 66 00               	push	0x6613a0
  663003: 68 b8 9f ca 00               	push	0xca9fb8
  663008: 57                           	push	edi
  663009: e8 c2 d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  66300e: 83 c4 78                     	add	esp, 0x78
  663011: 68 c0 13 66 00               	push	0x6613c0
  663016: 68 cc 9f ca 00               	push	0xca9fcc
  66301b: 57                           	push	edi
  66301c: e8 af d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663021: 68 00 14 66 00               	push	0x661400
  663026: 68 dc 9f ca 00               	push	0xca9fdc
  66302b: 57                           	push	edi
  66302c: e8 9f d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663031: 68 30 14 66 00               	push	0x661430
  663036: 68 ec 9f ca 00               	push	0xca9fec
  66303b: 57                           	push	edi
  66303c: e8 8f d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663041: 68 50 14 66 00               	push	0x661450
  663046: 68 00 a0 ca 00               	push	0xcaa000
  66304b: 57                           	push	edi
  66304c: e8 7f d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663051: 68 90 14 66 00               	push	0x661490
  663056: 68 14 a0 ca 00               	push	0xcaa014
  66305b: 57                           	push	edi
  66305c: e8 6f d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663061: 68 c0 14 66 00               	push	0x6614c0
  663066: 68 28 a0 ca 00               	push	0xcaa028
  66306b: 57                           	push	edi
  66306c: e8 5f d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663071: 68 e0 14 66 00               	push	0x6614e0
  663076: 68 40 a0 ca 00               	push	0xcaa040
  66307b: 57                           	push	edi
  66307c: e8 4f d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663081: 68 20 15 66 00               	push	0x661520
  663086: 68 50 a0 ca 00               	push	0xcaa050
  66308b: 57                           	push	edi
  66308c: e8 3f d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663091: 68 50 15 66 00               	push	0x661550
  663096: 68 60 a0 ca 00               	push	0xcaa060
  66309b: 57                           	push	edi
  66309c: e8 2f d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  6630a1: 68 70 15 66 00               	push	0x661570
  6630a6: 68 70 a0 ca 00               	push	0xcaa070
  6630ab: 57                           	push	edi
  6630ac: e8 1f d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  6630b1: 83 c4 78                     	add	esp, 0x78
  6630b4: 68 c0 15 66 00               	push	0x6615c0
  6630b9: 68 80 a0 ca 00               	push	0xcaa080
  6630be: 57                           	push	edi
  6630bf: e8 0c d5 22 00               	call	0x8905d0 <.text+0x48f5d0>
  6630c4: 68 00 16 66 00               	push	0x661600
  6630c9: 68 90 a0 ca 00               	push	0xcaa090
  6630ce: 57                           	push	edi
  6630cf: e8 fc d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  6630d4: 68 20 16 66 00               	push	0x661620
  6630d9: 68 a0 a0 ca 00               	push	0xcaa0a0
  6630de: 57                           	push	edi
  6630df: e8 ec d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  6630e4: 68 80 1a 66 00               	push	0x661a80
  6630e9: 68 b0 a0 ca 00               	push	0xcaa0b0
  6630ee: 57                           	push	edi
  6630ef: e8 dc d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  6630f4: 68 40 1e 66 00               	push	0x661e40
  6630f9: 68 c0 a0 ca 00               	push	0xcaa0c0
  6630fe: 57                           	push	edi
  6630ff: e8 cc d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663104: 68 60 1e 66 00               	push	0x661e60
  663109: 68 d4 a0 ca 00               	push	0xcaa0d4
  66310e: 57                           	push	edi
  66310f: e8 bc d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663114: 68 b0 1e 66 00               	push	0x661eb0
  663119: 68 e4 a0 ca 00               	push	0xcaa0e4
  66311e: 57                           	push	edi
  66311f: e8 ac d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663124: 68 00 1f 66 00               	push	0x661f00
  663129: 68 f4 a0 ca 00               	push	0xcaa0f4
  66312e: 57                           	push	edi
  66312f: e8 9c d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663134: 68 a0 1f 66 00               	push	0x661fa0
  663139: 68 f4 a0 ca 00               	push	0xcaa0f4
  66313e: 57                           	push	edi
  66313f: e8 8c d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663144: 68 b0 20 66 00               	push	0x6620b0
  663149: 68 04 a1 ca 00               	push	0xcaa104
  66314e: 57                           	push	edi
  66314f: e8 7c d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663154: 83 c4 78                     	add	esp, 0x78
  663157: 68 d0 20 66 00               	push	0x6620d0
  66315c: 68 10 a1 ca 00               	push	0xcaa110
  663161: 57                           	push	edi
  663162: e8 69 d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663167: 68 30 33 66 00               	push	0x663330
  66316c: 68 18 a1 ca 00               	push	0xcaa118
  663171: 57                           	push	edi
  663172: e8 59 d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663177: 68 f0 20 66 00               	push	0x6620f0
  66317c: 68 2c a1 ca 00               	push	0xcaa12c
  663181: 57                           	push	edi
  663182: e8 49 d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663187: 68 40 21 66 00               	push	0x662140
  66318c: 68 40 a1 ca 00               	push	0xcaa140
  663191: 57                           	push	edi
  663192: e8 39 d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  663197: 68 90 21 66 00               	push	0x662190
  66319c: 68 54 a1 ca 00               	push	0xcaa154
  6631a1: 57                           	push	edi
  6631a2: e8 29 d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  6631a7: 68 e0 21 66 00               	push	0x6621e0
  6631ac: 68 64 a1 ca 00               	push	0xcaa164
  6631b1: 57                           	push	edi
  6631b2: e8 19 d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  6631b7: 68 30 22 66 00               	push	0x662230
  6631bc: 68 74 a1 ca 00               	push	0xcaa174
  6631c1: 57                           	push	edi
  6631c2: e8 09 d4 22 00               	call	0x8905d0 <.text+0x48f5d0>
  6631c7: 68 b0 22 66 00               	push	0x6622b0
  6631cc: 68 80 a1 ca 00               	push	0xcaa180
  6631d1: 57                           	push	edi
  6631d2: e8 f9 d3 22 00               	call	0x8905d0 <.text+0x48f5d0>
  6631d7: 68 10 23 66 00               	push	0x662310
  6631dc: 68 8c a1 ca 00               	push	0xcaa18c
  6631e1: 57                           	push	edi
  6631e2: e8 e9 d3 22 00               	call	0x8905d0 <.text+0x48f5d0>
  6631e7: 68 40 23 66 00               	push	0x662340
  6631ec: 68 94 a1 ca 00               	push	0xcaa194
  6631f1: 57                           	push	edi
  6631f2: e8 d9 d3 22 00               	call	0x8905d0 <.text+0x48f5d0>
  6631f7: 83 c4 78                     	add	esp, 0x78
  6631fa: 68 70 23 66 00               	push	0x662370
  6631ff: 68 a0 a1 ca 00               	push	0xcaa1a0
  663204: 57                           	push	edi
  663205: e8 c6 d3 22 00               	call	0x8905d0 <.text+0x48f5d0>
  66320a: 68 e0 23 66 00               	push	0x6623e0
  66320f: 68 b0 23 66 00               	push	0x6623b0
  663214: 68 58 9e c3 00               	push	0xc39e58
  663219: 57                           	push	edi
  66321a: e8 11 d4 22 00               	call	0x890630 <.text+0x48f630>
  66321f: 68 50 24 66 00               	push	0x662450
  663224: 68 20 24 66 00               	push	0x662420
  663229: 68 60 9e c3 00               	push	0xc39e60
  66322e: 57                           	push	edi
  66322f: e8 fc d3 22 00               	call	0x890630 <.text+0x48f630>
  663234: 68 c0 24 66 00               	push	0x6624c0
  663239: 68 90 24 66 00               	push	0x662490
  66323e: 68 d4 ac c3 00               	push	0xc3acd4
  663243: 57                           	push	edi
  663244: e8 e7 d3 22 00               	call	0x890630 <.text+0x48f630>
  663249: 68 30 25 66 00               	push	0x662530
  66324e: 68 00 25 66 00               	push	0x662500
  663253: 68 ac a1 ca 00               	push	0xcaa1ac
  663258: 57                           	push	edi
  663259: e8 d2 d3 22 00               	call	0x890630 <.text+0x48f630>
  66325e: 68 a0 25 66 00               	push	0x6625a0
  663263: 68 70 25 66 00               	push	0x662570
  663268: 68 b8 a1 ca 00               	push	0xcaa1b8
  66326d: 57                           	push	edi
  66326e: e8 bd d3 22 00               	call	0x890630 <.text+0x48f630>
  663273: 68 10 26 66 00               	push	0x662610
  663278: 68 e0 25 66 00               	push	0x6625e0
  66327d: 68 c4 a1 ca 00               	push	0xcaa1c4
  663282: 57                           	push	edi
  663283: e8 a8 d3 22 00               	call	0x890630 <.text+0x48f630>
  663288: 68 80 26 66 00               	push	0x662680
  66328d: 68 50 26 66 00               	push	0x662650
  663292: 68 d4 a1 ca 00               	push	0xcaa1d4
  663297: 57                           	push	edi
  663298: e8 93 d3 22 00               	call	0x890630 <.text+0x48f630>
  66329d: 83 c4 7c                     	add	esp, 0x7c
  6632a0: 68 00 27 66 00               	push	0x662700
  6632a5: 68 c0 26 66 00               	push	0x6626c0
  6632aa: 68 e0 a1 ca 00               	push	0xcaa1e0
  6632af: 57                           	push	edi
  6632b0: e8 7b d3 22 00               	call	0x890630 <.text+0x48f630>
  6632b5: 68 00 28 66 00               	push	0x662800
  6632ba: 68 50 27 66 00               	push	0x662750
  6632bf: 68 ec a1 ca 00               	push	0xcaa1ec
  6632c4: 57                           	push	edi
  6632c5: e8 66 d3 22 00               	call	0x890630 <.text+0x48f630>
  6632ca: 68 80 2c 66 00               	push	0x662c80
  6632cf: 68 30 2c 66 00               	push	0x662c30
  6632d4: 68 f8 a1 ca 00               	push	0xcaa1f8
  6632d9: 57                           	push	edi
  6632da: e8 51 d3 22 00               	call	0x890630 <.text+0x48f630>
  6632df: 68 20 2d 66 00               	push	0x662d20
  6632e4: 68 d0 2c 66 00               	push	0x662cd0
  6632e9: 68 04 a2 ca 00               	push	0xcaa204
  6632ee: 57                           	push	edi
  6632ef: e8 3c d3 22 00               	call	0x890630 <.text+0x48f630>
  6632f4: 68 c0 2d 66 00               	push	0x662dc0
  6632f9: 68 70 2d 66 00               	push	0x662d70
  6632fe: 68 14 a2 ca 00               	push	0xcaa214
  663303: 57                           	push	edi
  663304: e8 27 d3 22 00               	call	0x890630 <.text+0x48f630>
  663309: 57                           	push	edi
  66330a: e8 01 d0 22 00               	call	0x890310 <.text+0x48f310>
  66330f: 57                           	push	edi
  663310: e8 fb cf 22 00               	call	0x890310 <.text+0x48f310>
  663315: 57                           	push	edi
  663316: e8 f5 cf 22 00               	call	0x890310 <.text+0x48f310>
  66331b: 83 c4 5c                     	add	esp, 0x5c
  66331e: b8 01 00 00 00               	mov	eax, 0x1
  663323: 83 c4 10                     	add	esp, 0x10
  663326: 5f                           	pop	edi
  663327: c3                           	ret
  663328: 90                           	nop
  663329: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  663330: 6a 00                        	push	0x0
  663332: 6a 01                        	push	0x1
  663334: ff 74 24 0c                  	push	dword ptr [esp + 0xc]
  663338: e8 33 c1 22 00               	call	0x88f470 <.text+0x48e470>
  66333d: 83 c4 0c                     	add	esp, 0xc
