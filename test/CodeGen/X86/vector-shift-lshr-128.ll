; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mcpu=x86-64 | FileCheck %s --check-prefix=ALL --check-prefix=SSE --check-prefix=SSE2
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mcpu=x86-64 -mattr=+sse4.1 | FileCheck %s --check-prefix=ALL --check-prefix=SSE --check-prefix=SSE41
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mcpu=x86-64 -mattr=+avx | FileCheck %s --check-prefix=ALL --check-prefix=AVX --check-prefix=AVX1
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mcpu=x86-64 -mattr=+avx2 | FileCheck %s --check-prefix=ALL --check-prefix=AVX --check-prefix=AVX2

;
; Variable Shifts
;

define <2 x i64> @var_shift_v2i64(<2 x i64> %a, <2 x i64> %b) {
; SSE2-LABEL: var_shift_v2i64:
; SSE2:       # BB#0:
; SSE2-NEXT:    pshufd {{.*#+}} xmm3 = xmm1[2,3,0,1]
; SSE2-NEXT:    movdqa %xmm0, %xmm2
; SSE2-NEXT:    psrlq  %xmm3, %xmm2
; SSE2-NEXT:    psrlq  %xmm1, %xmm0
; SSE2-NEXT:    movsd  {{.*#+}} xmm2 = xmm0[0],xmm2[1]
; SSE2-NEXT:    movapd %xmm2, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: var_shift_v2i64:
; SSE41:       # BB#0:
; SSE41-NEXT:    movdqa  %xmm0, %xmm2
; SSE41-NEXT:    psrlq   %xmm1, %xmm2
; SSE41-NEXT:    pshufd  {{.*#+}} xmm1 = xmm1[2,3,0,1]
; SSE41-NEXT:    psrlq   %xmm1, %xmm0
; SSE41-NEXT:    pblendw {{.*#+}} xmm0 = xmm2[0,1,2,3],xmm0[4,5,6,7]
; SSE41-NEXT:    retq
;
; AVX1-LABEL: var_shift_v2i64:
; AVX1:       # BB#0:
; AVX1-NEXT:    vpsrlq   %xmm1, %xmm0, %xmm2
; AVX1-NEXT:    vpshufd  {{.*#+}} xmm1 = xmm1[2,3,0,1]
; AVX1-NEXT:    vpsrlq   %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    vpblendw {{.*#+}} xmm0 = xmm2[0,1,2,3],xmm0[4,5,6,7]
; AVX1-NEXT:    retq
;
; AVX2-LABEL: var_shift_v2i64:
; AVX2:       # BB#0:
; AVX2-NEXT:    vpsrlvq %xmm1, %xmm0, %xmm0
; AVX2-NEXT:    retq
  %shift = lshr <2 x i64> %a, %b
  ret <2 x i64> %shift
}

define <4 x i32> @var_shift_v4i32(<4 x i32> %a, <4 x i32> %b) {
; SSE2-LABEL: var_shift_v4i32:
; SSE2:       # BB#0:
; SSE2-NEXT:    pshufd    {{.*#+}} xmm2 = xmm0[3,1,2,3]
; SSE2-NEXT:    movd      %xmm2, %eax
; SSE2-NEXT:    pshufd    {{.*#+}} xmm2 = xmm1[3,1,2,3]
; SSE2-NEXT:    movd      %xmm2, %ecx
; SSE2-NEXT:    shrl      %cl, %eax
; SSE2-NEXT:    movd      %eax, %xmm2
; SSE2-NEXT:    pshufd    {{.*#+}} xmm3 = xmm0[1,1,2,3]
; SSE2-NEXT:    movd      %xmm3, %eax
; SSE2-NEXT:    pshufd    {{.*#+}} xmm3 = xmm1[1,1,2,3]
; SSE2-NEXT:    movd      %xmm3, %ecx
; SSE2-NEXT:    shrl      %cl, %eax
; SSE2-NEXT:    movd      %eax, %xmm3
; SSE2-NEXT:    punpckldq {{.*#+}} xmm3 = xmm3[0],xmm2[0],xmm3[1],xmm2[1]
; SSE2-NEXT:    movd      %xmm0, %eax
; SSE2-NEXT:    movd      %xmm1, %ecx
; SSE2-NEXT:    shrl      %cl, %eax
; SSE2-NEXT:    movd      %eax, %xmm2
; SSE2-NEXT:    pshufd    {{.*#+}} xmm0 = xmm0[2,3,0,1]
; SSE2-NEXT:    movd      %xmm0, %eax
; SSE2-NEXT:    pshufd    {{.*#+}} xmm0 = xmm1[2,3,0,1]
; SSE2-NEXT:    movd      %xmm0, %ecx
; SSE2-NEXT:    shrl      %cl, %eax
; SSE2-NEXT:    movd      %eax, %xmm0
; SSE2-NEXT:    punpckldq {{.*#+}} xmm2 = xmm2[0],xmm0[0],xmm2[1],xmm0[1]
; SSE2-NEXT:    punpckldq {{.*#+}} xmm2 = xmm2[0],xmm3[0],xmm2[1],xmm3[1]
; SSE2-NEXT:    movdqa     %xmm2, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: var_shift_v4i32:
; SSE41:       # BB#0:
; SSE41-NEXT:    pextrd $1, %xmm0, %eax
; SSE41-NEXT:    pextrd $1, %xmm1, %ecx
; SSE41-NEXT:    shrl   %cl, %eax
; SSE41-NEXT:    movd   %xmm0, %edx
; SSE41-NEXT:    movd   %xmm1, %ecx
; SSE41-NEXT:    shrl   %cl, %edx
; SSE41-NEXT:    movd   %edx, %xmm2
; SSE41-NEXT:    pinsrd $1, %eax, %xmm2
; SSE41-NEXT:    pextrd $2, %xmm0, %eax
; SSE41-NEXT:    pextrd $2, %xmm1, %ecx
; SSE41-NEXT:    shrl   %cl, %eax
; SSE41-NEXT:    pinsrd $2, %eax, %xmm2
; SSE41-NEXT:    pextrd $3, %xmm0, %eax
; SSE41-NEXT:    pextrd $3, %xmm1, %ecx
; SSE41-NEXT:    shrl   %cl, %eax
; SSE41-NEXT:    pinsrd $3, %eax, %xmm2
; SSE41-NEXT:    movdqa %xmm2, %xmm0
; SSE41-NEXT:    retq
;
; AVX1-LABEL: var_shift_v4i32:
; AVX1:       # BB#0:
; AVX1-NEXT:    vpextrd $1, %xmm0, %eax
; AVX1-NEXT:    vpextrd $1, %xmm1, %ecx
; AVX1-NEXT:    shrl    %cl, %eax
; AVX1-NEXT:    vmovd   %xmm0, %edx
; AVX1-NEXT:    vmovd   %xmm1, %ecx
; AVX1-NEXT:    shrl    %cl, %edx
; AVX1-NEXT:    vmovd   %edx, %xmm2
; AVX1-NEXT:    vpinsrd $1, %eax, %xmm2, %xmm2
; AVX1-NEXT:    vpextrd $2, %xmm0, %eax
; AVX1-NEXT:    vpextrd $2, %xmm1, %ecx
; AVX1-NEXT:    shrl    %cl, %eax
; AVX1-NEXT:    vpinsrd $2, %eax, %xmm2, %xmm2
; AVX1-NEXT:    vpextrd $3, %xmm0, %eax
; AVX1-NEXT:    vpextrd $3, %xmm1, %ecx
; AVX1-NEXT:    shrl    %cl, %eax
; AVX1-NEXT:    vpinsrd $3, %eax, %xmm2, %xmm0
; AVX1-NEXT:    retq
;
; AVX2-LABEL: var_shift_v4i32:
; AVX2:       # BB#0:
; AVX2-NEXT:    vpsrlvd %xmm1, %xmm0, %xmm0
; AVX2-NEXT:    retq
  %shift = lshr <4 x i32> %a, %b
  ret <4 x i32> %shift
}

define <8 x i16> @var_shift_v8i16(<8 x i16> %a, <8 x i16> %b) {
; SSE2-LABEL: var_shift_v8i16:
; SSE2:       # BB#0:
; SSE2-NEXT:    psllw  $12, %xmm1
; SSE2-NEXT:    movdqa %xmm1, %xmm2
; SSE2-NEXT:    psraw  $15, %xmm2
; SSE2-NEXT:    movdqa %xmm2, %xmm3
; SSE2-NEXT:    pandn  %xmm0, %xmm3
; SSE2-NEXT:    psrlw  $8, %xmm0
; SSE2-NEXT:    pand   %xmm2, %xmm0
; SSE2-NEXT:    por    %xmm3, %xmm0
; SSE2-NEXT:    paddw  %xmm1, %xmm1
; SSE2-NEXT:    movdqa %xmm1, %xmm2
; SSE2-NEXT:    psraw  $15, %xmm2
; SSE2-NEXT:    movdqa %xmm2, %xmm3
; SSE2-NEXT:    pandn  %xmm0, %xmm3
; SSE2-NEXT:    psrlw  $4, %xmm0
; SSE2-NEXT:    pand   %xmm2, %xmm0
; SSE2-NEXT:    por    %xmm3, %xmm0
; SSE2-NEXT:    paddw  %xmm1, %xmm1
; SSE2-NEXT:    movdqa %xmm1, %xmm2
; SSE2-NEXT:    psraw  $15, %xmm2
; SSE2-NEXT:    movdqa %xmm2, %xmm3
; SSE2-NEXT:    pandn  %xmm0, %xmm3
; SSE2-NEXT:    psrlw  $2, %xmm0
; SSE2-NEXT:    pand   %xmm2, %xmm0
; SSE2-NEXT:    por    %xmm3, %xmm0
; SSE2-NEXT:    paddw  %xmm1, %xmm1
; SSE2-NEXT:    psraw  $15, %xmm1
; SSE2-NEXT:    movdqa %xmm1, %xmm2
; SSE2-NEXT:    pandn  %xmm0, %xmm2
; SSE2-NEXT:    psrlw  $1, %xmm0
; SSE2-NEXT:    pand   %xmm1, %xmm0
; SSE2-NEXT:    por    %xmm2, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: var_shift_v8i16:
; SSE41:       # BB#0:
; SSE41-NEXT:    movdqa   %xmm0, %xmm2
; SSE41-NEXT:    movdqa   %xmm1, %xmm0
; SSE41-NEXT:    psllw    $12, %xmm0
; SSE41-NEXT:    psllw    $4, %xmm1
; SSE41-NEXT:    por      %xmm0, %xmm1
; SSE41-NEXT:    movdqa   %xmm1, %xmm3
; SSE41-NEXT:    paddw    %xmm3, %xmm3
; SSE41-NEXT:    movdqa   %xmm2, %xmm4
; SSE41-NEXT:    psrlw    $8, %xmm4
; SSE41-NEXT:    movdqa   %xmm1, %xmm0
; SSE41-NEXT:    pblendvb %xmm4, %xmm2
; SSE41-NEXT:    movdqa   %xmm2, %xmm1
; SSE41-NEXT:    psrlw    $4, %xmm1
; SSE41-NEXT:    movdqa   %xmm3, %xmm0
; SSE41-NEXT:    pblendvb %xmm1, %xmm2
; SSE41-NEXT:    movdqa   %xmm2, %xmm1
; SSE41-NEXT:    psrlw    $2, %xmm1
; SSE41-NEXT:    paddw    %xmm3, %xmm3
; SSE41-NEXT:    movdqa   %xmm3, %xmm0
; SSE41-NEXT:    pblendvb %xmm1, %xmm2
; SSE41-NEXT:    movdqa   %xmm2, %xmm1
; SSE41-NEXT:    psrlw    $1, %xmm1
; SSE41-NEXT:    paddw    %xmm3, %xmm3
; SSE41-NEXT:    movdqa   %xmm3, %xmm0
; SSE41-NEXT:    pblendvb %xmm1, %xmm2
; SSE41-NEXT:    movdqa   %xmm2, %xmm0
; SSE41-NEXT:    retq
;
; AVX1-LABEL: var_shift_v8i16:
; AVX1:       # BB#0:
; AVX1-NEXT:    vpsllw    $12, %xmm1, %xmm2
; AVX1-NEXT:    vpsllw    $4, %xmm1, %xmm1
; AVX1-NEXT:    vpor      %xmm2, %xmm1, %xmm1
; AVX1-NEXT:    vpaddw    %xmm1, %xmm1, %xmm2
; AVX1-NEXT:    vpsrlw    $8, %xmm0, %xmm3
; AVX1-NEXT:    vpblendvb %xmm1, %xmm3, %xmm0, %xmm0
; AVX1-NEXT:    vpsrlw    $4, %xmm0, %xmm1
; AVX1-NEXT:    vpblendvb %xmm2, %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    vpsrlw    $2, %xmm0, %xmm1
; AVX1-NEXT:    vpaddw    %xmm2, %xmm2, %xmm2
; AVX1-NEXT:    vpblendvb %xmm2, %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    vpsrlw    $1, %xmm0, %xmm1
; AVX1-NEXT:    vpaddw    %xmm2, %xmm2, %xmm2
; AVX1-NEXT:    vpblendvb %xmm2, %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    retq
;
; AVX2-LABEL: var_shift_v8i16:
; AVX2:       # BB#0:
; AVX2-NEXT:    vpmovzxwd {{.*#+}} ymm1 = xmm1[0],zero,xmm1[1],zero,xmm1[2],zero,xmm1[3],zero,xmm1[4],zero,xmm1[5],zero,xmm1[6],zero,xmm1[7],zero
; AVX2-NEXT:    vpmovzxwd {{.*#+}} ymm0 = xmm0[0],zero,xmm0[1],zero,xmm0[2],zero,xmm0[3],zero,xmm0[4],zero,xmm0[5],zero,xmm0[6],zero,xmm0[7],zero
; AVX2-NEXT:    vpsrlvd   %ymm1, %ymm0, %ymm0
; AVX2-NEXT:    vpshufb   {{.*#+}} ymm0 = ymm0[0,1,4,5,8,9,12,13],zero,zero,zero,zero,zero,zero,zero,zero,ymm0[16,17,20,21,24,25,28,29],zero,zero,zero,zero,zero,zero,zero,zero
; AVX2-NEXT:    vpermq    {{.*#+}} ymm0 = ymm0[0,2,2,3]
; AVX2-NEXT:    vzeroupper
; AVX2-NEXT:    retq
  %shift = lshr <8 x i16> %a, %b
  ret <8 x i16> %shift
}

define <16 x i8> @var_shift_v16i8(<16 x i8> %a, <16 x i8> %b) {
; SSE2-LABEL: var_shift_v16i8:
; SSE2:       # BB#0:
; SSE2-NEXT:  psllw   $5, %xmm1
; SSE2-NEXT:  pxor    %xmm2, %xmm2
; SSE2-NEXT:  pxor    %xmm3, %xmm3
; SSE2-NEXT:  pcmpgtb %xmm1, %xmm3
; SSE2-NEXT:  movdqa  %xmm3, %xmm4
; SSE2-NEXT:  pandn   %xmm0, %xmm4
; SSE2-NEXT:  psrlw   $4, %xmm0
; SSE2-NEXT:  pand    {{.*}}(%rip), %xmm0
; SSE2-NEXT:  pand    %xmm3, %xmm0
; SSE2-NEXT:  por     %xmm4, %xmm0
; SSE2-NEXT:  paddb   %xmm1, %xmm1
; SSE2-NEXT:  pxor    %xmm3, %xmm3
; SSE2-NEXT:  pcmpgtb %xmm1, %xmm3
; SSE2-NEXT:  movdqa  %xmm3, %xmm4
; SSE2-NEXT:  pandn   %xmm0, %xmm4
; SSE2-NEXT:  psrlw   $2, %xmm0
; SSE2-NEXT:  pand    {{.*}}(%rip), %xmm0
; SSE2-NEXT:  pand    %xmm3, %xmm0
; SSE2-NEXT:  por     %xmm4, %xmm0
; SSE2-NEXT:  paddb   %xmm1, %xmm1
; SSE2-NEXT:  pcmpgtb %xmm1, %xmm2
; SSE2-NEXT:  movdqa  %xmm2, %xmm1
; SSE2-NEXT:  pandn   %xmm0, %xmm1
; SSE2-NEXT:  psrlw   $1, %xmm0
; SSE2-NEXT:  pand    {{.*}}(%rip), %xmm0
; SSE2-NEXT:  pand    %xmm2, %xmm0
; SSE2-NEXT:  por     %xmm1, %xmm0
; SSE2-NEXT:  retq
;
; SSE41-LABEL: var_shift_v16i8:
; SSE41:       # BB#0:
; SSE41-NEXT:    movdqa   %xmm0, %xmm2
; SSE41-NEXT:    psllw    $5, %xmm1
; SSE41-NEXT:    movdqa   %xmm2, %xmm3
; SSE41-NEXT:    psrlw    $4, %xmm3
; SSE41-NEXT:    pand     {{.*}}(%rip), %xmm3
; SSE41-NEXT:    movdqa   %xmm1, %xmm0
; SSE41-NEXT:    pblendvb %xmm3, %xmm2
; SSE41-NEXT:    movdqa   %xmm2, %xmm3
; SSE41-NEXT:    psrlw    $2, %xmm3
; SSE41-NEXT:    pand     {{.*}}(%rip), %xmm3
; SSE41-NEXT:    paddb    %xmm1, %xmm1
; SSE41-NEXT:    movdqa   %xmm1, %xmm0
; SSE41-NEXT:    pblendvb %xmm3, %xmm2
; SSE41-NEXT:    movdqa   %xmm2, %xmm3
; SSE41-NEXT:    psrlw    $1, %xmm3
; SSE41-NEXT:    pand     {{.*}}(%rip), %xmm3
; SSE41-NEXT:    paddb    %xmm1, %xmm1
; SSE41-NEXT:    movdqa   %xmm1, %xmm0
; SSE41-NEXT:    pblendvb %xmm3, %xmm2
; SSE41-NEXT:    movdqa   %xmm2, %xmm0
; SSE41-NEXT:    retq
;
; AVX-LABEL: var_shift_v16i8:
; AVX:       # BB#0:
; AVX-NEXT:    vpsllw    $5, %xmm1, %xmm1
; AVX-NEXT:    vpsrlw    $4, %xmm0, %xmm2
; AVX-NEXT:    vpand     {{.*}}(%rip), %xmm2, %xmm2
; AVX-NEXT:    vpblendvb %xmm1, %xmm2, %xmm0, %xmm0
; AVX-NEXT:    vpsrlw    $2, %xmm0, %xmm2
; AVX-NEXT:    vpand     {{.*}}(%rip), %xmm2, %xmm2
; AVX-NEXT:    vpaddb    %xmm1, %xmm1, %xmm1
; AVX-NEXT:    vpblendvb %xmm1, %xmm2, %xmm0, %xmm0
; AVX-NEXT:    vpsrlw    $1, %xmm0, %xmm2
; AVX-NEXT:    vpand     {{.*}}(%rip), %xmm2, %xmm2
; AVX-NEXT:    vpaddb    %xmm1, %xmm1, %xmm1
; AVX-NEXT:    vpblendvb %xmm1, %xmm2, %xmm0, %xmm0
; AVX-NEXT:    retq
  %shift = lshr <16 x i8> %a, %b
  ret <16 x i8> %shift
}

;
; Uniform Variable Shifts
;

define <2 x i64> @splatvar_shift_v2i64(<2 x i64> %a, <2 x i64> %b) {
; SSE-LABEL: splatvar_shift_v2i64:
; SSE:       # BB#0:
; SSE-NEXT:    psrlq %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: splatvar_shift_v2i64:
; AVX:       # BB#0:
; AVX-NEXT:    vpsrlq %xmm1, %xmm0, %xmm0
; AVX-NEXT:    retq
  %splat = shufflevector <2 x i64> %b, <2 x i64> undef, <2 x i32> zeroinitializer
  %shift = lshr <2 x i64> %a, %splat
  ret <2 x i64> %shift
}

define <4 x i32> @splatvar_shift_v4i32(<4 x i32> %a, <4 x i32> %b) {
; SSE2-LABEL: splatvar_shift_v4i32:
; SSE2:       # BB#0:
; SSE2-NEXT:    xorps %xmm2, %xmm2
; SSE2-NEXT:    movss {{.*#+}} xmm2 = xmm1[0],xmm2[1,2,3]
; SSE2-NEXT:    psrld %xmm2, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: splatvar_shift_v4i32:
; SSE41:       # BB#0:
; SSE41-NEXT:    pxor %xmm2, %xmm2
; SSE41-NEXT:    pblendw {{.*#+}} xmm2 = xmm1[0,1],xmm2[2,3,4,5,6,7]
; SSE41-NEXT:    psrld %xmm2, %xmm0
; SSE41-NEXT:    retq
;
; AVX-LABEL: splatvar_shift_v4i32:
; AVX:       # BB#0:
; AVX-NEXT:    vpxor %xmm2, %xmm2, %xmm2
; AVX-NEXT:    vpblendw {{.*#+}} xmm1 = xmm1[0,1],xmm2[2,3,4,5,6,7]
; AVX-NEXT:    vpsrld %xmm1, %xmm0, %xmm0
; AVX-NEXT:    retq
  %splat = shufflevector <4 x i32> %b, <4 x i32> undef, <4 x i32> zeroinitializer
  %shift = lshr <4 x i32> %a, %splat
  ret <4 x i32> %shift
}

define <8 x i16> @splatvar_shift_v8i16(<8 x i16> %a, <8 x i16> %b) {
; SSE2-LABEL: splatvar_shift_v8i16:
; SSE2:       # BB#0:
; SSE2-NEXT:    movd   %xmm1, %eax
; SSE2-NEXT:    movzwl %ax, %eax
; SSE2-NEXT:    movd   %eax, %xmm1
; SSE2-NEXT:    psrlw  %xmm1, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: splatvar_shift_v8i16:
; SSE41:       # BB#0:
; SSE41-NEXT:    pxor %xmm2, %xmm2
; SSE41-NEXT:    pblendw {{.*#+}} xmm2 = xmm1[0],xmm2[1,2,3,4,5,6,7]
; SSE41-NEXT:    psrlw %xmm2, %xmm0
; SSE41-NEXT:    retq
;
; AVX-LABEL: splatvar_shift_v8i16:
; AVX:       # BB#0:
; AVX-NEXT:    vpxor %xmm2, %xmm2, %xmm2
; AVX-NEXT:    vpblendw {{.*#+}} xmm1 = xmm1[0],xmm2[1,2,3,4,5,6,7]
; AVX-NEXT:    vpsrlw %xmm1, %xmm0, %xmm0
; AVX-NEXT:    retq
  %splat = shufflevector <8 x i16> %b, <8 x i16> undef, <8 x i32> zeroinitializer
  %shift = lshr <8 x i16> %a, %splat
  ret <8 x i16> %shift
}

define <16 x i8> @splatvar_shift_v16i8(<16 x i8> %a, <16 x i8> %b) {
; SSE2-LABEL: splatvar_shift_v16i8:
; SSE2:       # BB#0:
; SSE2-NEXT:  punpcklbw {{.*#+}} xmm1 = xmm1[0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7]
; SSE2-NEXT:  pshufd    {{.*#+}} xmm1 = xmm1[0,1,0,3]
; SSE2-NEXT:  pshuflw   {{.*#+}} xmm1 = xmm1[0,0,0,0,4,5,6,7]
; SSE2-NEXT:  pshufhw   {{.*#+}} xmm2 = xmm1[0,1,2,3,4,4,4,4]
; SSE2-NEXT:  psllw     $5, %xmm2
; SSE2-NEXT:  pxor      %xmm1, %xmm1
; SSE2-NEXT:  pxor      %xmm3, %xmm3
; SSE2-NEXT:  pcmpgtb   %xmm2, %xmm3
; SSE2-NEXT:  movdqa    %xmm3, %xmm4
; SSE2-NEXT:  pandn     %xmm0, %xmm4
; SSE2-NEXT:  psrlw     $4, %xmm0
; SSE2-NEXT:  pand      {{.*}}(%rip), %xmm0
; SSE2-NEXT:  pand      %xmm3, %xmm0
; SSE2-NEXT:  por       %xmm4, %xmm0
; SSE2-NEXT:  paddb     %xmm2, %xmm2
; SSE2-NEXT:  pxor      %xmm3, %xmm3
; SSE2-NEXT:  pcmpgtb   %xmm2, %xmm3
; SSE2-NEXT:  movdqa    %xmm3, %xmm4
; SSE2-NEXT:  pandn     %xmm0, %xmm4
; SSE2-NEXT:  psrlw     $2, %xmm0
; SSE2-NEXT:  pand      {{.*}}(%rip), %xmm0
; SSE2-NEXT:  pand      %xmm3, %xmm0
; SSE2-NEXT:  por       %xmm4, %xmm0
; SSE2-NEXT:  paddb     %xmm2, %xmm2
; SSE2-NEXT:  pcmpgtb   %xmm2, %xmm1
; SSE2-NEXT:  movdqa    %xmm1, %xmm2
; SSE2-NEXT:  pandn     %xmm0, %xmm2
; SSE2-NEXT:  psrlw     $1, %xmm0
; SSE2-NEXT:  pand      {{.*}}(%rip), %xmm0
; SSE2-NEXT:  pand      %xmm1, %xmm0
; SSE2-NEXT:  por       %xmm2, %xmm0
; SSE2-NEXT:  retq
;
; SSE41-LABEL: splatvar_shift_v16i8:
; SSE41:       # BB#0:
; SSE41-NEXT:    movdqa   %xmm0, %xmm2
; SSE41-NEXT:    pxor     %xmm0, %xmm0
; SSE41-NEXT:    pshufb   %xmm0, %xmm1
; SSE41-NEXT:    psllw    $5, %xmm1
; SSE41-NEXT:    movdqa   %xmm1, %xmm3
; SSE41-NEXT:    paddb    %xmm3, %xmm3
; SSE41-NEXT:    movdqa   %xmm2, %xmm4
; SSE41-NEXT:    psrlw    $4, %xmm4
; SSE41-NEXT:    pand     {{.*}}(%rip), %xmm4
; SSE41-NEXT:    movdqa   %xmm1, %xmm0
; SSE41-NEXT:    pblendvb %xmm4, %xmm2
; SSE41-NEXT:    movdqa   %xmm2, %xmm1
; SSE41-NEXT:    psrlw    $2, %xmm1
; SSE41-NEXT:    pand     {{.*}}(%rip), %xmm1
; SSE41-NEXT:    movdqa   %xmm3, %xmm0
; SSE41-NEXT:    pblendvb %xmm1, %xmm2
; SSE41-NEXT:    movdqa   %xmm2, %xmm1
; SSE41-NEXT:    psrlw    $1, %xmm1
; SSE41-NEXT:    pand     {{.*}}(%rip), %xmm1
; SSE41-NEXT:    paddb    %xmm3, %xmm3
; SSE41-NEXT:    movdqa   %xmm3, %xmm0
; SSE41-NEXT:    pblendvb %xmm1, %xmm2
; SSE41-NEXT:    movdqa   %xmm2, %xmm0
; SSE41-NEXT:    retq
;
; AVX1-LABEL: splatvar_shift_v16i8:
; AVX1:       # BB#0:
; AVX1-NEXT:    vpxor     %xmm2, %xmm2, %xmm2
; AVX1-NEXT:    vpshufb   %xmm2, %xmm1, %xmm1
; AVX1-NEXT:    vpsllw    $5, %xmm1, %xmm1
; AVX1-NEXT:    vpaddb    %xmm1, %xmm1, %xmm2
; AVX1-NEXT:    vpsrlw    $4, %xmm0, %xmm3
; AVX1-NEXT:    vpand     {{.*}}(%rip), %xmm3, %xmm3
; AVX1-NEXT:    vpblendvb %xmm1, %xmm3, %xmm0, %xmm0
; AVX1-NEXT:    vpsrlw    $2, %xmm0, %xmm1
; AVX1-NEXT:    vpand     {{.*}}(%rip), %xmm1, %xmm1
; AVX1-NEXT:    vpblendvb %xmm2, %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    vpsrlw    $1, %xmm0, %xmm1
; AVX1-NEXT:    vpand     {{.*}}(%rip), %xmm1, %xmm1
; AVX1-NEXT:    vpaddb    %xmm2, %xmm2, %xmm2
; AVX1-NEXT:    vpblendvb %xmm2, %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    retq
;
; AVX2-LABEL: splatvar_shift_v16i8:
; AVX2:       # BB#0:
; AVX2-NEXT:    vpbroadcastb %xmm1, %xmm1
; AVX2-NEXT:    vpsllw       $5, %xmm1, %xmm1
; AVX2-NEXT:    vpsrlw       $4, %xmm0, %xmm2
; AVX2-NEXT:    vpand        {{.*}}(%rip), %xmm2, %xmm2
; AVX2-NEXT:    vpblendvb    %xmm1, %xmm2, %xmm0, %xmm0
; AVX2-NEXT:    vpsrlw       $2, %xmm0, %xmm2
; AVX2-NEXT:    vpand        {{.*}}(%rip), %xmm2, %xmm2
; AVX2-NEXT:    vpaddb       %xmm1, %xmm1, %xmm1
; AVX2-NEXT:    vpblendvb    %xmm1, %xmm2, %xmm0, %xmm0
; AVX2-NEXT:    vpsrlw       $1, %xmm0, %xmm2
; AVX2-NEXT:    vpand        {{.*}}(%rip), %xmm2, %xmm2
; AVX2-NEXT:    vpaddb       %xmm1, %xmm1, %xmm1
; AVX2-NEXT:    vpblendvb    %xmm1, %xmm2, %xmm0, %xmm0
; AVX2-NEXT:    retq
  %splat = shufflevector <16 x i8> %b, <16 x i8> undef, <16 x i32> zeroinitializer
  %shift = lshr <16 x i8> %a, %splat
  ret <16 x i8> %shift
}

;
; Constant Shifts
;

define <2 x i64> @constant_shift_v2i64(<2 x i64> %a) {
; SSE2-LABEL: constant_shift_v2i64:
; SSE2:       # BB#0:
; SSE2-NEXT:    movdqa %xmm0, %xmm1
; SSE2-NEXT:    psrlq  $7, %xmm1
; SSE2-NEXT:    psrlq  $1, %xmm0
; SSE2-NEXT:    movsd  {{.*#+}} xmm1 = xmm0[0],xmm1[1]
; SSE2-NEXT:    movapd %xmm1, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: constant_shift_v2i64:
; SSE41:       # BB#0:
; SSE41-NEXT:    movdqa  %xmm0, %xmm1
; SSE41-NEXT:    psrlq   $7, %xmm1
; SSE41-NEXT:    psrlq   $1, %xmm0
; SSE41-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; SSE41-NEXT:    retq
;
; AVX1-LABEL: constant_shift_v2i64:
; AVX1:       # BB#0:
; AVX1-NEXT:    vpsrlq  $7, %xmm0, %xmm1
; AVX1-NEXT:    vpsrlq  $1, %xmm0, %xmm0
; AVX1-NEXT:    vpblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; AVX1-NEXT:    retq
;
; AVX2-LABEL: constant_shift_v2i64:
; AVX2:       # BB#0:
; AVX2-NEXT:    vpsrlvq {{.*}}(%rip), %xmm0, %xmm0
; AVX2-NEXT:    retq
  %shift = lshr <2 x i64> %a, <i64 1, i64 7>
  ret <2 x i64> %shift
}

define <4 x i32> @constant_shift_v4i32(<4 x i32> %a) {
; SSE2-LABEL: constant_shift_v4i32:
; SSE2:       # BB#0:
; SSE2-NEXT:    pshufd    {{.*#+}} xmm1 = xmm0[3,1,2,3]
; SSE2-NEXT:    movd      %xmm1, %eax
; SSE2-NEXT:    shrl      $7, %eax
; SSE2-NEXT:    movd      %eax, %xmm1
; SSE2-NEXT:    pshufd    {{.*#+}} xmm2 = xmm0[1,1,2,3]
; SSE2-NEXT:    movd      %xmm2, %eax
; SSE2-NEXT:    shrl      $5, %eax
; SSE2-NEXT:    movd      %eax, %xmm2
; SSE2-NEXT:    punpckldq {{.*#+}} xmm2 = xmm2[0],xmm1[0],xmm2[1],xmm1[1]
; SSE2-NEXT:    movd      %xmm0, %eax
; SSE2-NEXT:    shrl      $4, %eax
; SSE2-NEXT:    movd      %eax, %xmm1
; SSE2-NEXT:    pshufd    {{.*#+}} xmm0 = xmm0[2,3,0,1]
; SSE2-NEXT:    movd      %xmm0, %eax
; SSE2-NEXT:    shrl      $6, %eax
; SSE2-NEXT:    movd      %eax, %xmm0
; SSE2-NEXT:    punpckldq {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
; SSE2-NEXT:    punpckldq {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1]
; SSE2-NEXT:    movdqa    %xmm1, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: constant_shift_v4i32:
; SSE41:       # BB#0:
; SSE41-NEXT:    pextrd $1, %xmm0, %eax
; SSE41-NEXT:    shrl   $5, %eax
; SSE41-NEXT:    movd   %xmm0, %ecx
; SSE41-NEXT:    shrl   $4, %ecx
; SSE41-NEXT:    movd   %ecx, %xmm1
; SSE41-NEXT:    pinsrd $1, %eax, %xmm1
; SSE41-NEXT:    pextrd $2, %xmm0, %eax
; SSE41-NEXT:    shrl   $6, %eax
; SSE41-NEXT:    pinsrd $2, %eax, %xmm1
; SSE41-NEXT:    pextrd $3, %xmm0, %eax
; SSE41-NEXT:    shrl   $7, %eax
; SSE41-NEXT:    pinsrd $3, %eax, %xmm1
; SSE41-NEXT:    movdqa %xmm1, %xmm0
; SSE41-NEXT:    retq
;
; AVX1-LABEL: constant_shift_v4i32:
; AVX1:       # BB#0:
; AVX1-NEXT:    vpextrd $1, %xmm0, %eax
; AVX1-NEXT:    shrl    $5, %eax
; AVX1-NEXT:    vmovd   %xmm0, %ecx
; AVX1-NEXT:    shrl    $4, %ecx
; AVX1-NEXT:    vmovd   %ecx, %xmm1
; AVX1-NEXT:    vpinsrd $1, %eax, %xmm1, %xmm1
; AVX1-NEXT:    vpextrd $2, %xmm0, %eax
; AVX1-NEXT:    shrl    $6, %eax
; AVX1-NEXT:    vpinsrd $2, %eax, %xmm1, %xmm1
; AVX1-NEXT:    vpextrd $3, %xmm0, %eax
; AVX1-NEXT:    shrl    $7, %eax
; AVX1-NEXT:    vpinsrd $3, %eax, %xmm1, %xmm0
; AVX1-NEXT:    retq
;
; AVX2-LABEL: constant_shift_v4i32:
; AVX2:       # BB#0:
; AVX2-NEXT:    vpsrlvd {{.*}}(%rip), %xmm0, %xmm0
; AVX2-NEXT:    retq
  %shift = lshr <4 x i32> %a, <i32 4, i32 5, i32 6, i32 7>
  ret <4 x i32> %shift
}

define <8 x i16> @constant_shift_v8i16(<8 x i16> %a) {
; SSE2-LABEL: constant_shift_v8i16:
; SSE2:       # BB#0:
; SSE2-NEXT:    movdqa    %xmm0, %xmm1
; SSE2-NEXT:    psrlw     $4, %xmm1
; SSE2-NEXT:    movsd     {{.*#+}} xmm1 = xmm0[0],xmm1[1]
; SSE2-NEXT:    pshufd    {{.*#+}} xmm2 = xmm1[0,2,2,3]
; SSE2-NEXT:    psrlw     $2, %xmm1
; SSE2-NEXT:    pshufd    {{.*#+}}  xmm0 = xmm1[1,3,2,3]
; SSE2-NEXT:    punpckldq {{.*#+}} xmm2 = xmm2[0],xmm0[0],xmm2[1],xmm0[1]
; SSE2-NEXT:    movdqa    {{.*#+}} xmm0 = [65535,0,65535,0,65535,0,65535,0]
; SSE2-NEXT:    movdqa    %xmm2, %xmm1
; SSE2-NEXT:    pand      %xmm0, %xmm1
; SSE2-NEXT:    psrlw     $1, %xmm2
; SSE2-NEXT:    pandn     %xmm2, %xmm0
; SSE2-NEXT:    por       %xmm1, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: constant_shift_v8i16:
; SSE41:       # BB#0:
; SSE41-NEXT:    movdqa   %xmm0, %xmm1
; SSE41-NEXT:    movdqa   %xmm1, %xmm2
; SSE41-NEXT:    psrlw    $8, %xmm2
; SSE41-NEXT:    movaps   {{.*#+}} xmm0 = [0,4112,8224,12336,16448,20560,24672,28784]
; SSE41-NEXT:    pblendvb %xmm2, %xmm1
; SSE41-NEXT:    movdqa   %xmm1, %xmm2
; SSE41-NEXT:    psrlw    $4, %xmm2
; SSE41-NEXT:    movaps   {{.*#+}} xmm0 = [0,8224,16448,24672,32896,41120,49344,57568]
; SSE41-NEXT:    pblendvb %xmm2, %xmm1
; SSE41-NEXT:    movdqa   %xmm1, %xmm2
; SSE41-NEXT:    psrlw    $2, %xmm2
; SSE41-NEXT:    movaps   {{.*#+}} xmm0 = [0,16448,32896,49344,256,16704,33152,49600]
; SSE41-NEXT:    pblendvb %xmm2, %xmm1
; SSE41-NEXT:    movdqa   %xmm1, %xmm2
; SSE41-NEXT:    psrlw    $1, %xmm2
; SSE41-NEXT:    movaps   {{.*#+}} xmm0 = [0,32896,256,33152,512,33408,768,33664]
; SSE41-NEXT:    pblendvb %xmm2, %xmm1
; SSE41-NEXT:    movdqa   %xmm1, %xmm0
; SSE41-NEXT:    retq
;
; AVX1-LABEL: constant_shift_v8i16:
; AVX1:       # BB#0:
; AVX1-NEXT:    vpsrlw    $8, %xmm0, %xmm1
; AVX1-NEXT:    vmovdqa   {{.*}}(%rip), %xmm2  # xmm2 = [0,4112,8224,12336,16448,20560,24672,28784]
; AVX1-NEXT:    vpblendvb %xmm2, %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    vpsrlw    $4, %xmm0, %xmm1
; AVX1-NEXT:    vmovdqa   {{.*}}(%rip), %xmm2  # xmm2 = [0,8224,16448,24672,32896,41120,49344,57568]
; AVX1-NEXT:    vpblendvb %xmm2, %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    vpsrlw    $2, %xmm0, %xmm1
; AVX1-NEXT:    vmovdqa   {{.*}}(%rip), %xmm2  # xmm2 = [0,16448,32896,49344,256,16704,33152,49600]
; AVX1-NEXT:    vpblendvb %xmm2, %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    vpsrlw    $1, %xmm0, %xmm1
; AVX1-NEXT:    vmovdqa   {{.*}}(%rip), %xmm2  # xmm2 = [0,32896,256,33152,512,33408,768,33664]
; AVX1-NEXT:    vpblendvb %xmm2, %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    retq
;
; AVX2-LABEL: constant_shift_v8i16:
; AVX2:       # BB#0:
; AVX2-NEXT:    vpmovzxwd {{.*#+}} ymm0 = xmm0[0],zero,xmm0[1],zero,xmm0[2],zero,xmm0[3],zero,xmm0[4],zero,xmm0[5],zero,xmm0[6],zero,xmm0[7],zero
; AVX2-NEXT:    vpmovzxwd {{.*#+}} ymm1 = mem[0],zero,mem[1],zero,mem[2],zero,mem[3],zero,mem[4],zero,mem[5],zero,mem[6],zero,mem[7],zero
; AVX2-NEXT:    vpsrlvd   %ymm1, %ymm0, %ymm0
; AVX2-NEXT:    vpshufb   {{.*#+}} ymm0 = ymm0[0,1,4,5,8,9,12,13],zero,zero,zero,zero,zero,zero,zero,zero,ymm0[16,17,20,21,24,25,28,29],zero,zero,zero,zero,zero,zero,zero,zero
; AVX2-NEXT:    vpermq    {{.*#+}} ymm0 = ymm0[0,2,2,3]
; AVX2-NEXT:    vzeroupper
; AVX2-NEXT:    retq
  %shift = lshr <8 x i16> %a, <i16 0, i16 1, i16 2, i16 3, i16 4, i16 5, i16 6, i16 7>
  ret <8 x i16> %shift
}

define <16 x i8> @constant_shift_v16i8(<16 x i8> %a) {
; SSE2-LABEL: constant_shift_v16i8:
; SSE2:       # BB#0:
; SSE2-NEXT:    movdqa  {{.*#+}} xmm2 = [0,1,2,3,4,5,6,7,7,6,5,4,3,2,1,0]
; SSE2-NEXT:    psllw   $5, %xmm2
; SSE2-NEXT:    pxor    %xmm1, %xmm1
; SSE2-NEXT:    pxor    %xmm3, %xmm3
; SSE2-NEXT:    pcmpgtb %xmm2, %xmm3
; SSE2-NEXT:    movdqa  %xmm3, %xmm4
; SSE2-NEXT:    pandn   %xmm0, %xmm4
; SSE2-NEXT:    psrlw   $4, %xmm0
; SSE2-NEXT:    pand    {{.*}}(%rip), %xmm0
; SSE2-NEXT:    pand    %xmm3, %xmm0
; SSE2-NEXT:    por     %xmm4, %xmm0
; SSE2-NEXT:    paddb   %xmm2, %xmm2
; SSE2-NEXT:    pxor    %xmm3, %xmm3
; SSE2-NEXT:    pcmpgtb %xmm2, %xmm3
; SSE2-NEXT:    movdqa  %xmm3, %xmm4
; SSE2-NEXT:    pandn   %xmm0, %xmm4
; SSE2-NEXT:    psrlw   $2, %xmm0
; SSE2-NEXT:    pand    {{.*}}(%rip), %xmm0
; SSE2-NEXT:    pand    %xmm3, %xmm0
; SSE2-NEXT:    por     %xmm4, %xmm0
; SSE2-NEXT:    paddb   %xmm2, %xmm2
; SSE2-NEXT:    pcmpgtb %xmm2, %xmm1
; SSE2-NEXT:    movdqa  %xmm1, %xmm2
; SSE2-NEXT:    pandn   %xmm0, %xmm2
; SSE2-NEXT:    psrlw   $1, %xmm0
; SSE2-NEXT:    pand    {{.*}}(%rip), %xmm0
; SSE2-NEXT:    pand    %xmm1, %xmm0
; SSE2-NEXT:    por     %xmm2, %xmm0
; SSE2-NEXT:    retq
;
; SSE41-LABEL: constant_shift_v16i8:
; SSE41:       # BB#0:
; SSE41-NEXT:    movdqa   %xmm0, %xmm1
; SSE41-NEXT:    movdqa   {{.*#+}} xmm0 = [0,1,2,3,4,5,6,7,7,6,5,4,3,2,1,0]
; SSE41-NEXT:    psllw    $5, %xmm0
; SSE41-NEXT:    movdqa   %xmm1, %xmm2
; SSE41-NEXT:    psrlw    $4, %xmm2
; SSE41-NEXT:    pand     {{.*}}(%rip), %xmm2
; SSE41-NEXT:    pblendvb %xmm2, %xmm1
; SSE41-NEXT:    movdqa   %xmm1, %xmm2
; SSE41-NEXT:    psrlw    $2, %xmm2
; SSE41-NEXT:    pand     {{.*}}(%rip), %xmm2
; SSE41-NEXT:    paddb    %xmm0, %xmm0
; SSE41-NEXT:    pblendvb %xmm2, %xmm1
; SSE41-NEXT:    movdqa   %xmm1, %xmm2
; SSE41-NEXT:    psrlw    $1, %xmm2
; SSE41-NEXT:    pand     {{.*}}(%rip), %xmm2
; SSE41-NEXT:    paddb    %xmm0, %xmm0
; SSE41-NEXT:    pblendvb %xmm2, %xmm1
; SSE41-NEXT:    movdqa   %xmm1, %xmm0
; SSE41-NEXT:    retq
;
; AVX-LABEL: constant_shift_v16i8:
; AVX:       # BB#0:
; AVX-NEXT:    vmovdqa   {{.*#+}} xmm1 = [0,1,2,3,4,5,6,7,7,6,5,4,3,2,1,0]
; AVX-NEXT:    vpsllw    $5, %xmm1, %xmm1
; AVX-NEXT:    vpsrlw    $4, %xmm0, %xmm2
; AVX-NEXT:    vpand     {{.*}}(%rip), %xmm2, %xmm2
; AVX-NEXT:    vpblendvb %xmm1, %xmm2, %xmm0, %xmm0
; AVX-NEXT:    vpsrlw    $2, %xmm0, %xmm2
; AVX-NEXT:    vpand     {{.*}}(%rip), %xmm2, %xmm2
; AVX-NEXT:    vpaddb    %xmm1, %xmm1, %xmm1
; AVX-NEXT:    vpblendvb %xmm1, %xmm2, %xmm0, %xmm0
; AVX-NEXT:    vpsrlw    $1, %xmm0, %xmm2
; AVX-NEXT:    vpand     {{.*}}(%rip), %xmm2, %xmm2
; AVX-NEXT:    vpaddb    %xmm1, %xmm1, %xmm1
; AVX-NEXT:    vpblendvb %xmm1, %xmm2, %xmm0, %xmm0
; AVX-NEXT:    retq
  %shift = lshr <16 x i8> %a, <i8 0, i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7, i8 7, i8 6, i8 5, i8 4, i8 3, i8 2, i8 1, i8 0>
  ret <16 x i8> %shift
}

;
; Uniform Constant Shifts
;

define <2 x i64> @splatconstant_shift_v2i64(<2 x i64> %a) {
; SSE-LABEL: splatconstant_shift_v2i64:
; SSE:       # BB#0:
; SSE-NEXT:    psrlq $7, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: splatconstant_shift_v2i64:
; AVX:       # BB#0:
; AVX-NEXT:    vpsrlq $7, %xmm0, %xmm0
; AVX-NEXT:    retq
  %shift = lshr <2 x i64> %a, <i64 7, i64 7>
  ret <2 x i64> %shift
}

define <4 x i32> @splatconstant_shift_v4i32(<4 x i32> %a) {
; SSE-LABEL: splatconstant_shift_v4i32:
; SSE:       # BB#0:
; SSE-NEXT:    psrld $5, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: splatconstant_shift_v4i32:
; AVX:       # BB#0:
; AVX-NEXT:    vpsrld $5, %xmm0, %xmm0
; AVX-NEXT:    retq
  %shift = lshr <4 x i32> %a, <i32 5, i32 5, i32 5, i32 5>
  ret <4 x i32> %shift
}

define <8 x i16> @splatconstant_shift_v8i16(<8 x i16> %a) {
; SSE-LABEL: splatconstant_shift_v8i16:
; SSE:       # BB#0:
; SSE-NEXT:    psrlw $3, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: splatconstant_shift_v8i16:
; AVX:       # BB#0:
; AVX-NEXT:    vpsrlw $3, %xmm0, %xmm0
; AVX-NEXT:    retq
  %shift = lshr <8 x i16> %a, <i16 3, i16 3, i16 3, i16 3, i16 3, i16 3, i16 3, i16 3>
  ret <8 x i16> %shift
}

define <16 x i8> @splatconstant_shift_v16i8(<16 x i8> %a) {
; SSE-LABEL: splatconstant_shift_v16i8:
; SSE:       # BB#0:
; SSE-NEXT:    psrlw     $3, %xmm0
; SSE-NEXT:    pand      {{.*}}(%rip), %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: splatconstant_shift_v16i8:
; AVX:       # BB#0:
; AVX-NEXT:    vpsrlw    $3, %xmm0
; AVX-NEXT:    vpand     {{.*}}(%rip), %xmm0
; AVX-NEXT:    retq
  %shift = lshr <16 x i8> %a, <i8 3, i8 3, i8 3, i8 3, i8 3, i8 3, i8 3, i8 3, i8 3, i8 3, i8 3, i8 3, i8 3, i8 3, i8 3, i8 3>
  ret <16 x i8> %shift
}
