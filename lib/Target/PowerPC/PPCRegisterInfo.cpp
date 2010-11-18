//===- PPCRegisterInfo.cpp - PowerPC Register Information -------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the PowerPC implementation of the TargetRegisterInfo
// class.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "reginfo"
#include "PPC.h"
#include "PPCInstrBuilder.h"
#include "PPCMachineFunctionInfo.h"
#include "PPCRegisterInfo.h"
#include "PPCFrameInfo.h"
#include "PPCSubtarget.h"
#include "llvm/CallingConv.h"
#include "llvm/Constants.h"
#include "llvm/Function.h"
#include "llvm/Type.h"
#include "llvm/CodeGen/ValueTypes.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineLocation.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/RegisterScavenging.h"
#include "llvm/Target/TargetFrameInfo.h"
#include "llvm/Target/TargetInstrInfo.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/STLExtras.h"
#include <cstdlib>

// FIXME (64-bit): Eventually enable by default.
namespace llvm {
cl::opt<bool> EnablePPC32RS("enable-ppc32-regscavenger",
                                   cl::init(false),
                                   cl::desc("Enable PPC32 register scavenger"),
                                   cl::Hidden);
cl::opt<bool> EnablePPC64RS("enable-ppc64-regscavenger",
                                   cl::init(false),
                                   cl::desc("Enable PPC64 register scavenger"),
                                   cl::Hidden);
}

using namespace llvm;

#define EnableRegisterScavenging \
  ((EnablePPC32RS && !Subtarget.isPPC64()) || \
   (EnablePPC64RS && Subtarget.isPPC64()))

// FIXME (64-bit): Should be inlined.
bool
PPCRegisterInfo::requiresRegisterScavenging(const MachineFunction &) const {
  return EnableRegisterScavenging;
}

/// getRegisterNumbering - Given the enum value for some register, e.g.
/// PPC::F14, return the number that it corresponds to (e.g. 14).
unsigned PPCRegisterInfo::getRegisterNumbering(unsigned RegEnum) {
  using namespace PPC;
  switch (RegEnum) {
  case 0: return 0;
  case R0 :  case X0 :  case F0 :  case V0 : case CR0:  case CR0LT: return  0;
  case R1 :  case X1 :  case F1 :  case V1 : case CR1:  case CR0GT: return  1;
  case R2 :  case X2 :  case F2 :  case V2 : case CR2:  case CR0EQ: return  2;
  case R3 :  case X3 :  case F3 :  case V3 : case CR3:  case CR0UN: return  3;
  case R4 :  case X4 :  case F4 :  case V4 : case CR4:  case CR1LT: return  4;
  case R5 :  case X5 :  case F5 :  case V5 : case CR5:  case CR1GT: return  5;
  case R6 :  case X6 :  case F6 :  case V6 : case CR6:  case CR1EQ: return  6;
  case R7 :  case X7 :  case F7 :  case V7 : case CR7:  case CR1UN: return  7;
  case R8 :  case X8 :  case F8 :  case V8 : case CR2LT: return  8;
  case R9 :  case X9 :  case F9 :  case V9 : case CR2GT: return  9;
  case R10:  case X10:  case F10:  case V10: case CR2EQ: return 10;
  case R11:  case X11:  case F11:  case V11: case CR2UN: return 11;
  case R12:  case X12:  case F12:  case V12: case CR3LT: return 12;
  case R13:  case X13:  case F13:  case V13: case CR3GT: return 13;
  case R14:  case X14:  case F14:  case V14: case CR3EQ: return 14;
  case R15:  case X15:  case F15:  case V15: case CR3UN: return 15;
  case R16:  case X16:  case F16:  case V16: case CR4LT: return 16;
  case R17:  case X17:  case F17:  case V17: case CR4GT: return 17;
  case R18:  case X18:  case F18:  case V18: case CR4EQ: return 18;
  case R19:  case X19:  case F19:  case V19: case CR4UN: return 19;
  case R20:  case X20:  case F20:  case V20: case CR5LT: return 20;
  case R21:  case X21:  case F21:  case V21: case CR5GT: return 21;
  case R22:  case X22:  case F22:  case V22: case CR5EQ: return 22;
  case R23:  case X23:  case F23:  case V23: case CR5UN: return 23;
  case R24:  case X24:  case F24:  case V24: case CR6LT: return 24;
  case R25:  case X25:  case F25:  case V25: case CR6GT: return 25;
  case R26:  case X26:  case F26:  case V26: case CR6EQ: return 26;
  case R27:  case X27:  case F27:  case V27: case CR6UN: return 27;
  case R28:  case X28:  case F28:  case V28: case CR7LT: return 28;
  case R29:  case X29:  case F29:  case V29: case CR7GT: return 29;
  case R30:  case X30:  case F30:  case V30: case CR7EQ: return 30;
  case R31:  case X31:  case F31:  case V31: case CR7UN: return 31;
  default:
    llvm_unreachable("Unhandled reg in PPCRegisterInfo::getRegisterNumbering!");
  }
}

PPCRegisterInfo::PPCRegisterInfo(const PPCSubtarget &ST,
                                 const TargetInstrInfo &tii)
  : PPCGenRegisterInfo(PPC::ADJCALLSTACKDOWN, PPC::ADJCALLSTACKUP),
    Subtarget(ST), TII(tii) {
  ImmToIdxMap[PPC::LD]   = PPC::LDX;    ImmToIdxMap[PPC::STD]  = PPC::STDX;
  ImmToIdxMap[PPC::LBZ]  = PPC::LBZX;   ImmToIdxMap[PPC::STB]  = PPC::STBX;
  ImmToIdxMap[PPC::LHZ]  = PPC::LHZX;   ImmToIdxMap[PPC::LHA]  = PPC::LHAX;
  ImmToIdxMap[PPC::LWZ]  = PPC::LWZX;   ImmToIdxMap[PPC::LWA]  = PPC::LWAX;
  ImmToIdxMap[PPC::LFS]  = PPC::LFSX;   ImmToIdxMap[PPC::LFD]  = PPC::LFDX;
  ImmToIdxMap[PPC::STH]  = PPC::STHX;   ImmToIdxMap[PPC::STW]  = PPC::STWX;
  ImmToIdxMap[PPC::STFS] = PPC::STFSX;  ImmToIdxMap[PPC::STFD] = PPC::STFDX;
  ImmToIdxMap[PPC::ADDI] = PPC::ADD4;

  // 64-bit
  ImmToIdxMap[PPC::LHA8] = PPC::LHAX8; ImmToIdxMap[PPC::LBZ8] = PPC::LBZX8;
  ImmToIdxMap[PPC::LHZ8] = PPC::LHZX8; ImmToIdxMap[PPC::LWZ8] = PPC::LWZX8;
  ImmToIdxMap[PPC::STB8] = PPC::STBX8; ImmToIdxMap[PPC::STH8] = PPC::STHX8;
  ImmToIdxMap[PPC::STW8] = PPC::STWX8; ImmToIdxMap[PPC::STDU] = PPC::STDUX;
  ImmToIdxMap[PPC::ADDI8] = PPC::ADD8; ImmToIdxMap[PPC::STD_32] = PPC::STDX_32;
}

/// getPointerRegClass - Return the register class to use to hold pointers.
/// This is used for addressing modes.
const TargetRegisterClass *
PPCRegisterInfo::getPointerRegClass(unsigned Kind) const {
  if (Subtarget.isPPC64())
    return &PPC::G8RCRegClass;
  return &PPC::GPRCRegClass;
}

const unsigned*
PPCRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  // 32-bit Darwin calling convention. 
  static const unsigned Darwin32_CalleeSavedRegs[] = {
              PPC::R13, PPC::R14, PPC::R15,
    PPC::R16, PPC::R17, PPC::R18, PPC::R19,
    PPC::R20, PPC::R21, PPC::R22, PPC::R23,
    PPC::R24, PPC::R25, PPC::R26, PPC::R27,
    PPC::R28, PPC::R29, PPC::R30, PPC::R31,

    PPC::F14, PPC::F15, PPC::F16, PPC::F17,
    PPC::F18, PPC::F19, PPC::F20, PPC::F21,
    PPC::F22, PPC::F23, PPC::F24, PPC::F25,
    PPC::F26, PPC::F27, PPC::F28, PPC::F29,
    PPC::F30, PPC::F31,
    
    PPC::CR2, PPC::CR3, PPC::CR4,
    PPC::V20, PPC::V21, PPC::V22, PPC::V23,
    PPC::V24, PPC::V25, PPC::V26, PPC::V27,
    PPC::V28, PPC::V29, PPC::V30, PPC::V31,
    
    PPC::CR2LT, PPC::CR2GT, PPC::CR2EQ, PPC::CR2UN,
    PPC::CR3LT, PPC::CR3GT, PPC::CR3EQ, PPC::CR3UN,
    PPC::CR4LT, PPC::CR4GT, PPC::CR4EQ, PPC::CR4UN,
    
    PPC::LR,  0
  };

  // 32-bit SVR4 calling convention.
  static const unsigned SVR4_CalleeSavedRegs[] = {
                        PPC::R14, PPC::R15,
    PPC::R16, PPC::R17, PPC::R18, PPC::R19,
    PPC::R20, PPC::R21, PPC::R22, PPC::R23,
    PPC::R24, PPC::R25, PPC::R26, PPC::R27,
    PPC::R28, PPC::R29, PPC::R30, PPC::R31,

    PPC::F14, PPC::F15, PPC::F16, PPC::F17,
    PPC::F18, PPC::F19, PPC::F20, PPC::F21,
    PPC::F22, PPC::F23, PPC::F24, PPC::F25,
    PPC::F26, PPC::F27, PPC::F28, PPC::F29,
    PPC::F30, PPC::F31,
    
    PPC::CR2, PPC::CR3, PPC::CR4,
    
    PPC::VRSAVE,
    
    PPC::V20, PPC::V21, PPC::V22, PPC::V23,
    PPC::V24, PPC::V25, PPC::V26, PPC::V27,
    PPC::V28, PPC::V29, PPC::V30, PPC::V31,
    
    PPC::CR2LT, PPC::CR2GT, PPC::CR2EQ, PPC::CR2UN,
    PPC::CR3LT, PPC::CR3GT, PPC::CR3EQ, PPC::CR3UN,
    PPC::CR4LT, PPC::CR4GT, PPC::CR4EQ, PPC::CR4UN,
    
    0
  };
  // 64-bit Darwin calling convention. 
  static const unsigned Darwin64_CalleeSavedRegs[] = {
    PPC::X14, PPC::X15,
    PPC::X16, PPC::X17, PPC::X18, PPC::X19,
    PPC::X20, PPC::X21, PPC::X22, PPC::X23,
    PPC::X24, PPC::X25, PPC::X26, PPC::X27,
    PPC::X28, PPC::X29, PPC::X30, PPC::X31,
    
    PPC::F14, PPC::F15, PPC::F16, PPC::F17,
    PPC::F18, PPC::F19, PPC::F20, PPC::F21,
    PPC::F22, PPC::F23, PPC::F24, PPC::F25,
    PPC::F26, PPC::F27, PPC::F28, PPC::F29,
    PPC::F30, PPC::F31,
    
    PPC::CR2, PPC::CR3, PPC::CR4,
    PPC::V20, PPC::V21, PPC::V22, PPC::V23,
    PPC::V24, PPC::V25, PPC::V26, PPC::V27,
    PPC::V28, PPC::V29, PPC::V30, PPC::V31,
    
    PPC::CR2LT, PPC::CR2GT, PPC::CR2EQ, PPC::CR2UN,
    PPC::CR3LT, PPC::CR3GT, PPC::CR3EQ, PPC::CR3UN,
    PPC::CR4LT, PPC::CR4GT, PPC::CR4EQ, PPC::CR4UN,
    
    PPC::LR8,  0
  };

  // 64-bit SVR4 calling convention.
  static const unsigned SVR4_64_CalleeSavedRegs[] = {
    PPC::X14, PPC::X15,
    PPC::X16, PPC::X17, PPC::X18, PPC::X19,
    PPC::X20, PPC::X21, PPC::X22, PPC::X23,
    PPC::X24, PPC::X25, PPC::X26, PPC::X27,
    PPC::X28, PPC::X29, PPC::X30, PPC::X31,

    PPC::F14, PPC::F15, PPC::F16, PPC::F17,
    PPC::F18, PPC::F19, PPC::F20, PPC::F21,
    PPC::F22, PPC::F23, PPC::F24, PPC::F25,
    PPC::F26, PPC::F27, PPC::F28, PPC::F29,
    PPC::F30, PPC::F31,

    PPC::CR2, PPC::CR3, PPC::CR4,

    PPC::VRSAVE,

    PPC::V20, PPC::V21, PPC::V22, PPC::V23,
    PPC::V24, PPC::V25, PPC::V26, PPC::V27,
    PPC::V28, PPC::V29, PPC::V30, PPC::V31,

    PPC::CR2LT, PPC::CR2GT, PPC::CR2EQ, PPC::CR2UN,
    PPC::CR3LT, PPC::CR3GT, PPC::CR3EQ, PPC::CR3UN,
    PPC::CR4LT, PPC::CR4GT, PPC::CR4EQ, PPC::CR4UN,

    0
  };
  
  if (Subtarget.isDarwinABI())
    return Subtarget.isPPC64() ? Darwin64_CalleeSavedRegs :
                                 Darwin32_CalleeSavedRegs;

  return Subtarget.isPPC64() ? SVR4_64_CalleeSavedRegs : SVR4_CalleeSavedRegs;
}

static bool spillsCR(const MachineFunction &MF) {
  const PPCFunctionInfo *FuncInfo = MF.getInfo<PPCFunctionInfo>();
  return FuncInfo->isCRSpilled();
}

BitVector PPCRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());
  const TargetFrameInfo *TFI = MF.getTarget().getFrameInfo();

  Reserved.set(PPC::R0);
  Reserved.set(PPC::R1);
  Reserved.set(PPC::LR);
  Reserved.set(PPC::LR8);
  Reserved.set(PPC::RM);

  // The SVR4 ABI reserves r2 and r13
  if (Subtarget.isSVR4ABI()) {
    Reserved.set(PPC::R2);  // System-reserved register
    Reserved.set(PPC::R13); // Small Data Area pointer register
  }
  // Reserve R2 on Darwin to hack around the problem of save/restore of CR
  // when the stack frame is too big to address directly; we need two regs.
  // This is a hack.
  if (Subtarget.isDarwinABI()) {
    Reserved.set(PPC::R2);
  }
  
  // On PPC64, r13 is the thread pointer. Never allocate this register.
  // Note that this is over conservative, as it also prevents allocation of R31
  // when the FP is not needed.
  if (Subtarget.isPPC64()) {
    Reserved.set(PPC::R13);
    Reserved.set(PPC::R31);

    if (!EnableRegisterScavenging)
      Reserved.set(PPC::R0);    // FIXME (64-bit): Remove

    Reserved.set(PPC::X0);
    Reserved.set(PPC::X1);
    Reserved.set(PPC::X13);
    Reserved.set(PPC::X31);

    // The 64-bit SVR4 ABI reserves r2 for the TOC pointer.
    if (Subtarget.isSVR4ABI()) {
      Reserved.set(PPC::X2);
    }
    // Reserve R2 on Darwin to hack around the problem of save/restore of CR
    // when the stack frame is too big to address directly; we need two regs.
    // This is a hack.
    if (Subtarget.isDarwinABI()) {
      Reserved.set(PPC::X2);
    }
  }

  if (TFI->hasFP(MF))
    Reserved.set(PPC::R31);

  return Reserved;
}

//===----------------------------------------------------------------------===//
// Stack Frame Processing methods
//===----------------------------------------------------------------------===//

/// MustSaveLR - Return true if this function requires that we save the LR
/// register onto the stack in the prolog and restore it in the epilog of the
/// function.
static bool MustSaveLR(const MachineFunction &MF, unsigned LR) {
  const PPCFunctionInfo *MFI = MF.getInfo<PPCFunctionInfo>();
  
  // We need a save/restore of LR if there is any def of LR (which is
  // defined by calls, including the PIC setup sequence), or if there is
  // some use of the LR stack slot (e.g. for builtin_return_address).
  // (LR comes in 32 and 64 bit versions.)
  MachineRegisterInfo::def_iterator RI = MF.getRegInfo().def_begin(LR);
  return RI !=MF.getRegInfo().def_end() || MFI->isLRStoreRequired();
}



void PPCRegisterInfo::
eliminateCallFramePseudoInstr(MachineFunction &MF, MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator I) const {
  if (GuaranteedTailCallOpt && I->getOpcode() == PPC::ADJCALLSTACKUP) {
    // Add (actually subtract) back the amount the callee popped on return.
    if (int CalleeAmt =  I->getOperand(1).getImm()) {
      bool is64Bit = Subtarget.isPPC64();
      CalleeAmt *= -1;
      unsigned StackReg = is64Bit ? PPC::X1 : PPC::R1;
      unsigned TmpReg = is64Bit ? PPC::X0 : PPC::R0;
      unsigned ADDIInstr = is64Bit ? PPC::ADDI8 : PPC::ADDI;
      unsigned ADDInstr = is64Bit ? PPC::ADD8 : PPC::ADD4;
      unsigned LISInstr = is64Bit ? PPC::LIS8 : PPC::LIS;
      unsigned ORIInstr = is64Bit ? PPC::ORI8 : PPC::ORI;
      MachineInstr *MI = I;
      DebugLoc dl = MI->getDebugLoc();

      if (isInt<16>(CalleeAmt)) {
        BuildMI(MBB, I, dl, TII.get(ADDIInstr), StackReg).addReg(StackReg).
          addImm(CalleeAmt);
      } else {
        MachineBasicBlock::iterator MBBI = I;
        BuildMI(MBB, MBBI, dl, TII.get(LISInstr), TmpReg)
          .addImm(CalleeAmt >> 16);
        BuildMI(MBB, MBBI, dl, TII.get(ORIInstr), TmpReg)
          .addReg(TmpReg, RegState::Kill)
          .addImm(CalleeAmt & 0xFFFF);
        BuildMI(MBB, MBBI, dl, TII.get(ADDInstr))
          .addReg(StackReg)
          .addReg(StackReg)
          .addReg(TmpReg);
      }
    }
  }
  // Simply discard ADJCALLSTACKDOWN, ADJCALLSTACKUP instructions.
  MBB.erase(I);
}

/// findScratchRegister - Find a 'free' PPC register. Try for a call-clobbered
/// register first and then a spilled callee-saved register if that fails.
static
unsigned findScratchRegister(MachineBasicBlock::iterator II, RegScavenger *RS,
                             const TargetRegisterClass *RC, int SPAdj) {
  assert(RS && "Register scavenging must be on");
  unsigned Reg = RS->FindUnusedReg(RC);
  // FIXME: move ARM callee-saved reg scan to target independent code, then 
  // search for already spilled CS register here.
  if (Reg == 0)
    Reg = RS->scavengeRegister(RC, II, SPAdj);
  return Reg;
}

/// lowerDynamicAlloc - Generate the code for allocating an object in the
/// current frame.  The sequence of code with be in the general form
///
///   addi   R0, SP, \#frameSize ; get the address of the previous frame
///   stwxu  R0, SP, Rnegsize   ; add and update the SP with the negated size
///   addi   Rnew, SP, \#maxCalFrameSize ; get the top of the allocation
///
void PPCRegisterInfo::lowerDynamicAlloc(MachineBasicBlock::iterator II,
                                        int SPAdj, RegScavenger *RS) const {
  // Get the instruction.
  MachineInstr &MI = *II;
  // Get the instruction's basic block.
  MachineBasicBlock &MBB = *MI.getParent();
  // Get the basic block's function.
  MachineFunction &MF = *MBB.getParent();
  // Get the frame info.
  MachineFrameInfo *MFI = MF.getFrameInfo();
  // Determine whether 64-bit pointers are used.
  bool LP64 = Subtarget.isPPC64();
  DebugLoc dl = MI.getDebugLoc();

  // Get the maximum call stack size.
  unsigned maxCallFrameSize = MFI->getMaxCallFrameSize();
  // Get the total frame size.
  unsigned FrameSize = MFI->getStackSize();
  
  // Get stack alignments.
  unsigned TargetAlign = MF.getTarget().getFrameInfo()->getStackAlignment();
  unsigned MaxAlign = MFI->getMaxAlignment();
  if (MaxAlign > TargetAlign)
    report_fatal_error("Dynamic alloca with large aligns not supported");

  // Determine the previous frame's address.  If FrameSize can't be
  // represented as 16 bits or we need special alignment, then we load the
  // previous frame's address from 0(SP).  Why not do an addis of the hi? 
  // Because R0 is our only safe tmp register and addi/addis treat R0 as zero. 
  // Constructing the constant and adding would take 3 instructions. 
  // Fortunately, a frame greater than 32K is rare.
  const TargetRegisterClass *G8RC = &PPC::G8RCRegClass;
  const TargetRegisterClass *GPRC = &PPC::GPRCRegClass;
  const TargetRegisterClass *RC = LP64 ? G8RC : GPRC;

  // FIXME (64-bit): Use "findScratchRegister"
  unsigned Reg;
  if (EnableRegisterScavenging)
    Reg = findScratchRegister(II, RS, RC, SPAdj);
  else
    Reg = PPC::R0;
  
  if (MaxAlign < TargetAlign && isInt<16>(FrameSize)) {
    BuildMI(MBB, II, dl, TII.get(PPC::ADDI), Reg)
      .addReg(PPC::R31)
      .addImm(FrameSize);
  } else if (LP64) {
    if (EnableRegisterScavenging) // FIXME (64-bit): Use "true" part.
      BuildMI(MBB, II, dl, TII.get(PPC::LD), Reg)
        .addImm(0)
        .addReg(PPC::X1);
    else
      BuildMI(MBB, II, dl, TII.get(PPC::LD), PPC::X0)
        .addImm(0)
        .addReg(PPC::X1);
  } else {
    BuildMI(MBB, II, dl, TII.get(PPC::LWZ), Reg)
      .addImm(0)
      .addReg(PPC::R1);
  }
  
  // Grow the stack and update the stack pointer link, then determine the
  // address of new allocated space.
  if (LP64) {
    if (EnableRegisterScavenging) // FIXME (64-bit): Use "true" part.
      BuildMI(MBB, II, dl, TII.get(PPC::STDUX))
        .addReg(Reg, RegState::Kill)
        .addReg(PPC::X1)
        .addReg(MI.getOperand(1).getReg());
    else
      BuildMI(MBB, II, dl, TII.get(PPC::STDUX))
        .addReg(PPC::X0, RegState::Kill)
        .addReg(PPC::X1)
        .addReg(MI.getOperand(1).getReg());

    if (!MI.getOperand(1).isKill())
      BuildMI(MBB, II, dl, TII.get(PPC::ADDI8), MI.getOperand(0).getReg())
        .addReg(PPC::X1)
        .addImm(maxCallFrameSize);
    else
      // Implicitly kill the register.
      BuildMI(MBB, II, dl, TII.get(PPC::ADDI8), MI.getOperand(0).getReg())
        .addReg(PPC::X1)
        .addImm(maxCallFrameSize)
        .addReg(MI.getOperand(1).getReg(), RegState::ImplicitKill);
  } else {
    BuildMI(MBB, II, dl, TII.get(PPC::STWUX))
      .addReg(Reg, RegState::Kill)
      .addReg(PPC::R1)
      .addReg(MI.getOperand(1).getReg());

    if (!MI.getOperand(1).isKill())
      BuildMI(MBB, II, dl, TII.get(PPC::ADDI), MI.getOperand(0).getReg())
        .addReg(PPC::R1)
        .addImm(maxCallFrameSize);
    else
      // Implicitly kill the register.
      BuildMI(MBB, II, dl, TII.get(PPC::ADDI), MI.getOperand(0).getReg())
        .addReg(PPC::R1)
        .addImm(maxCallFrameSize)
        .addReg(MI.getOperand(1).getReg(), RegState::ImplicitKill);
  }
  
  // Discard the DYNALLOC instruction.
  MBB.erase(II);
}

/// lowerCRSpilling - Generate the code for spilling a CR register. Instead of
/// reserving a whole register (R0), we scrounge for one here. This generates
/// code like this:
///
///   mfcr rA                  ; Move the conditional register into GPR rA.
///   rlwinm rA, rA, SB, 0, 31 ; Shift the bits left so they are in CR0's slot.
///   stw rA, FI               ; Store rA to the frame.
///
void PPCRegisterInfo::lowerCRSpilling(MachineBasicBlock::iterator II,
                                      unsigned FrameIndex, int SPAdj,
                                      RegScavenger *RS) const {
  // Get the instruction.
  MachineInstr &MI = *II;       // ; SPILL_CR <SrcReg>, <offset>, <FI>
  // Get the instruction's basic block.
  MachineBasicBlock &MBB = *MI.getParent();
  DebugLoc dl = MI.getDebugLoc();

  const TargetRegisterClass *G8RC = &PPC::G8RCRegClass;
  const TargetRegisterClass *GPRC = &PPC::GPRCRegClass;
  const TargetRegisterClass *RC = Subtarget.isPPC64() ? G8RC : GPRC;
  unsigned Reg = findScratchRegister(II, RS, RC, SPAdj);
  unsigned SrcReg = MI.getOperand(0).getReg();

  // We need to store the CR in the low 4-bits of the saved value. First, issue
  // an MFCRpsued to save all of the CRBits and, if needed, kill the SrcReg.
  BuildMI(MBB, II, dl, TII.get(PPC::MFCRpseud), Reg)
          .addReg(SrcReg, getKillRegState(MI.getOperand(0).isKill()));
    
  // If the saved register wasn't CR0, shift the bits left so that they are in
  // CR0's slot.
  if (SrcReg != PPC::CR0)
    // rlwinm rA, rA, ShiftBits, 0, 31.
    BuildMI(MBB, II, dl, TII.get(PPC::RLWINM), Reg)
      .addReg(Reg, RegState::Kill)
      .addImm(PPCRegisterInfo::getRegisterNumbering(SrcReg) * 4)
      .addImm(0)
      .addImm(31);

  addFrameReference(BuildMI(MBB, II, dl, TII.get(PPC::STW))
                    .addReg(Reg, getKillRegState(MI.getOperand(1).getImm())),
                    FrameIndex);

  // Discard the pseudo instruction.
  MBB.erase(II);
}

void
PPCRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                     int SPAdj, RegScavenger *RS) const {
  assert(SPAdj == 0 && "Unexpected");

  // Get the instruction.
  MachineInstr &MI = *II;
  // Get the instruction's basic block.
  MachineBasicBlock &MBB = *MI.getParent();
  // Get the basic block's function.
  MachineFunction &MF = *MBB.getParent();
  // Get the frame info.
  MachineFrameInfo *MFI = MF.getFrameInfo();
  const TargetFrameInfo *TFI = MF.getTarget().getFrameInfo();
  DebugLoc dl = MI.getDebugLoc();

  // Find out which operand is the frame index.
  unsigned FIOperandNo = 0;
  while (!MI.getOperand(FIOperandNo).isFI()) {
    ++FIOperandNo;
    assert(FIOperandNo != MI.getNumOperands() &&
           "Instr doesn't have FrameIndex operand!");
  }
  // Take into account whether it's an add or mem instruction
  unsigned OffsetOperandNo = (FIOperandNo == 2) ? 1 : 2;
  if (MI.isInlineAsm())
    OffsetOperandNo = FIOperandNo-1;

  // Get the frame index.
  int FrameIndex = MI.getOperand(FIOperandNo).getIndex();

  // Get the frame pointer save index.  Users of this index are primarily
  // DYNALLOC instructions.
  PPCFunctionInfo *FI = MF.getInfo<PPCFunctionInfo>();
  int FPSI = FI->getFramePointerSaveIndex();
  // Get the instruction opcode.
  unsigned OpC = MI.getOpcode();
  
  // Special case for dynamic alloca.
  if (FPSI && FrameIndex == FPSI &&
      (OpC == PPC::DYNALLOC || OpC == PPC::DYNALLOC8)) {
    lowerDynamicAlloc(II, SPAdj, RS);
    return;
  }

  // Special case for pseudo-op SPILL_CR.
  if (EnableRegisterScavenging) // FIXME (64-bit): Enable by default.
    if (OpC == PPC::SPILL_CR) {
      lowerCRSpilling(II, FrameIndex, SPAdj, RS);
      return;
    }

  // Replace the FrameIndex with base register with GPR1 (SP) or GPR31 (FP).
  MI.getOperand(FIOperandNo).ChangeToRegister(TFI->hasFP(MF) ?
                                              PPC::R31 : PPC::R1,
                                              false);

  // Figure out if the offset in the instruction is shifted right two bits. This
  // is true for instructions like "STD", which the machine implicitly adds two
  // low zeros to.
  bool isIXAddr = false;
  switch (OpC) {
  case PPC::LWA:
  case PPC::LD:
  case PPC::STD:
  case PPC::STD_32:
    isIXAddr = true;
    break;
  }
  
  // Now add the frame object offset to the offset from r1.
  int Offset = MFI->getObjectOffset(FrameIndex);
  if (!isIXAddr)
    Offset += MI.getOperand(OffsetOperandNo).getImm();
  else
    Offset += MI.getOperand(OffsetOperandNo).getImm() << 2;

  // If we're not using a Frame Pointer that has been set to the value of the
  // SP before having the stack size subtracted from it, then add the stack size
  // to Offset to get the correct offset.
  // Naked functions have stack size 0, although getStackSize may not reflect that
  // because we didn't call all the pieces that compute it for naked functions.
  if (!MF.getFunction()->hasFnAttr(Attribute::Naked))
    Offset += MFI->getStackSize();

  // If we can, encode the offset directly into the instruction.  If this is a
  // normal PPC "ri" instruction, any 16-bit value can be safely encoded.  If
  // this is a PPC64 "ix" instruction, only a 16-bit value with the low two bits
  // clear can be encoded.  This is extremely uncommon, because normally you
  // only "std" to a stack slot that is at least 4-byte aligned, but it can
  // happen in invalid code.
  if (isInt<16>(Offset) && (!isIXAddr || (Offset & 3) == 0)) {
    if (isIXAddr)
      Offset >>= 2;    // The actual encoded value has the low two bits zero.
    MI.getOperand(OffsetOperandNo).ChangeToImmediate(Offset);
    return;
  }

  // The offset doesn't fit into a single register, scavenge one to build the
  // offset in.
  // FIXME: figure out what SPAdj is doing here.

  // FIXME (64-bit): Use "findScratchRegister".
  unsigned SReg;
  if (EnableRegisterScavenging)
    SReg = findScratchRegister(II, RS, &PPC::GPRCRegClass, SPAdj);
  else
    SReg = PPC::R0;

  // Insert a set of rA with the full offset value before the ld, st, or add
  BuildMI(MBB, II, dl, TII.get(PPC::LIS), SReg)
    .addImm(Offset >> 16);
  BuildMI(MBB, II, dl, TII.get(PPC::ORI), SReg)
    .addReg(SReg, RegState::Kill)
    .addImm(Offset);

  // Convert into indexed form of the instruction:
  // 
  //   sth 0:rA, 1:imm 2:(rB) ==> sthx 0:rA, 2:rB, 1:r0
  //   addi 0:rA 1:rB, 2, imm ==> add 0:rA, 1:rB, 2:r0
  unsigned OperandBase;

  if (OpC != TargetOpcode::INLINEASM) {
    assert(ImmToIdxMap.count(OpC) &&
           "No indexed form of load or store available!");
    unsigned NewOpcode = ImmToIdxMap.find(OpC)->second;
    MI.setDesc(TII.get(NewOpcode));
    OperandBase = 1;
  } else {
    OperandBase = OffsetOperandNo;
  }

  unsigned StackReg = MI.getOperand(FIOperandNo).getReg();
  MI.getOperand(OperandBase).ChangeToRegister(StackReg, false);
  MI.getOperand(OperandBase + 1).ChangeToRegister(SReg, false);
}

void
PPCRegisterInfo::processFunctionBeforeCalleeSavedScan(MachineFunction &MF,
                                                      RegScavenger *RS) const {
  const TargetFrameInfo *TFI = MF.getTarget().getFrameInfo();

  //  Save and clear the LR state.
  PPCFunctionInfo *FI = MF.getInfo<PPCFunctionInfo>();
  unsigned LR = getRARegister();
  FI->setMustSaveLR(MustSaveLR(MF, LR));
  MF.getRegInfo().setPhysRegUnused(LR);

  //  Save R31 if necessary
  int FPSI = FI->getFramePointerSaveIndex();
  bool isPPC64 = Subtarget.isPPC64();
  bool isDarwinABI  = Subtarget.isDarwinABI();
  MachineFrameInfo *MFI = MF.getFrameInfo();

  // If the frame pointer save index hasn't been defined yet.
  if (!FPSI && TFI->hasFP(MF)) {
    // Find out what the fix offset of the frame pointer save area.
    int FPOffset = PPCFrameInfo::getFramePointerSaveOffset(isPPC64,
                                                           isDarwinABI);
    // Allocate the frame index for frame pointer save area.
    FPSI = MF.getFrameInfo()->CreateFixedObject(isPPC64? 8 : 4, FPOffset, true);
    // Save the result.
    FI->setFramePointerSaveIndex(FPSI);
  }

  // Reserve stack space to move the linkage area to in case of a tail call.
  int TCSPDelta = 0;
  if (GuaranteedTailCallOpt && (TCSPDelta = FI->getTailCallSPDelta()) < 0) {
    MF.getFrameInfo()->CreateFixedObject(-1 * TCSPDelta, TCSPDelta, true);
  }

  // Reserve a slot closest to SP or frame pointer if we have a dynalloc or
  // a large stack, which will require scavenging a register to materialize a
  // large offset.
  // FIXME: this doesn't actually check stack size, so is a bit pessimistic
  // FIXME: doesn't detect whether or not we need to spill vXX, which requires
  //        r0 for now.

  if (EnableRegisterScavenging) // FIXME (64-bit): Enable.
    if (TFI->hasFP(MF) || spillsCR(MF)) {
      const TargetRegisterClass *GPRC = &PPC::GPRCRegClass;
      const TargetRegisterClass *G8RC = &PPC::G8RCRegClass;
      const TargetRegisterClass *RC = isPPC64 ? G8RC : GPRC;
      RS->setScavengingFrameIndex(MFI->CreateStackObject(RC->getSize(),
                                                         RC->getAlignment(),
                                                         false));
    }
}

void
PPCRegisterInfo::processFunctionBeforeFrameFinalized(MachineFunction &MF)
                                                     const {
  // Early exit if not using the SVR4 ABI.
  if (!Subtarget.isSVR4ABI()) {
    return;
  }

  // Get callee saved register information.
  MachineFrameInfo *FFI = MF.getFrameInfo();
  const std::vector<CalleeSavedInfo> &CSI = FFI->getCalleeSavedInfo();
  const TargetFrameInfo *TFI = MF.getTarget().getFrameInfo();

  // Early exit if no callee saved registers are modified!
  if (CSI.empty() && !TFI->hasFP(MF)) {
    return;
  }

  unsigned MinGPR = PPC::R31;
  unsigned MinG8R = PPC::X31;
  unsigned MinFPR = PPC::F31;
  unsigned MinVR = PPC::V31;
  
  bool HasGPSaveArea = false;
  bool HasG8SaveArea = false;
  bool HasFPSaveArea = false;
  bool HasCRSaveArea = false;
  bool HasVRSAVESaveArea = false;
  bool HasVRSaveArea = false;
  
  SmallVector<CalleeSavedInfo, 18> GPRegs;
  SmallVector<CalleeSavedInfo, 18> G8Regs;
  SmallVector<CalleeSavedInfo, 18> FPRegs;
  SmallVector<CalleeSavedInfo, 18> VRegs;
  
  for (unsigned i = 0, e = CSI.size(); i != e; ++i) {
    unsigned Reg = CSI[i].getReg();
    if (PPC::GPRCRegisterClass->contains(Reg)) {
      HasGPSaveArea = true;
      
      GPRegs.push_back(CSI[i]);
      
      if (Reg < MinGPR) {
        MinGPR = Reg;
      }
    } else if (PPC::G8RCRegisterClass->contains(Reg)) {
      HasG8SaveArea = true;

      G8Regs.push_back(CSI[i]);

      if (Reg < MinG8R) {
        MinG8R = Reg;
      }
    } else if (PPC::F8RCRegisterClass->contains(Reg)) {
      HasFPSaveArea = true;
      
      FPRegs.push_back(CSI[i]);
      
      if (Reg < MinFPR) {
        MinFPR = Reg;
      }
// FIXME SVR4: Disable CR save area for now.
    } else if (PPC::CRBITRCRegisterClass->contains(Reg)
               || PPC::CRRCRegisterClass->contains(Reg)) {
//      HasCRSaveArea = true;
    } else if (PPC::VRSAVERCRegisterClass->contains(Reg)) {
      HasVRSAVESaveArea = true;
    } else if (PPC::VRRCRegisterClass->contains(Reg)) {
      HasVRSaveArea = true;
      
      VRegs.push_back(CSI[i]);
      
      if (Reg < MinVR) {
        MinVR = Reg;
      }
    } else {
      llvm_unreachable("Unknown RegisterClass!");
    }
  }

  PPCFunctionInfo *PFI = MF.getInfo<PPCFunctionInfo>();
  
  int64_t LowerBound = 0;

  // Take into account stack space reserved for tail calls.
  int TCSPDelta = 0;
  if (GuaranteedTailCallOpt && (TCSPDelta = PFI->getTailCallSPDelta()) < 0) {
    LowerBound = TCSPDelta;
  }

  // The Floating-point register save area is right below the back chain word
  // of the previous stack frame.
  if (HasFPSaveArea) {
    for (unsigned i = 0, e = FPRegs.size(); i != e; ++i) {
      int FI = FPRegs[i].getFrameIdx();
      
      FFI->setObjectOffset(FI, LowerBound + FFI->getObjectOffset(FI));
    }
    
    LowerBound -= (31 - getRegisterNumbering(MinFPR) + 1) * 8; 
  }

  // Check whether the frame pointer register is allocated. If so, make sure it
  // is spilled to the correct offset.
  if (TFI->hasFP(MF)) {
    HasGPSaveArea = true;
    
    int FI = PFI->getFramePointerSaveIndex();
    assert(FI && "No Frame Pointer Save Slot!");
    
    FFI->setObjectOffset(FI, LowerBound + FFI->getObjectOffset(FI));
  }
  
  // General register save area starts right below the Floating-point
  // register save area.
  if (HasGPSaveArea || HasG8SaveArea) {
    // Move general register save area spill slots down, taking into account
    // the size of the Floating-point register save area.
    for (unsigned i = 0, e = GPRegs.size(); i != e; ++i) {
      int FI = GPRegs[i].getFrameIdx();
      
      FFI->setObjectOffset(FI, LowerBound + FFI->getObjectOffset(FI));
    }
    
    // Move general register save area spill slots down, taking into account
    // the size of the Floating-point register save area.
    for (unsigned i = 0, e = G8Regs.size(); i != e; ++i) {
      int FI = G8Regs[i].getFrameIdx();

      FFI->setObjectOffset(FI, LowerBound + FFI->getObjectOffset(FI));
    }

    unsigned MinReg = std::min<unsigned>(getRegisterNumbering(MinGPR),
                                         getRegisterNumbering(MinG8R));

    if (Subtarget.isPPC64()) {
      LowerBound -= (31 - MinReg + 1) * 8;
    } else {
      LowerBound -= (31 - MinReg + 1) * 4;
    }
  }
  
  // The CR save area is below the general register save area.
  if (HasCRSaveArea) {
    // FIXME SVR4: Is it actually possible to have multiple elements in CSI
    //             which have the CR/CRBIT register class?
    // Adjust the frame index of the CR spill slot.
    for (unsigned i = 0, e = CSI.size(); i != e; ++i) {
      unsigned Reg = CSI[i].getReg();
    
      if (PPC::CRBITRCRegisterClass->contains(Reg) ||
          PPC::CRRCRegisterClass->contains(Reg)) {
        int FI = CSI[i].getFrameIdx();

        FFI->setObjectOffset(FI, LowerBound + FFI->getObjectOffset(FI));
      }
    }
    
    LowerBound -= 4; // The CR save area is always 4 bytes long.
  }
  
  if (HasVRSAVESaveArea) {
    // FIXME SVR4: Is it actually possible to have multiple elements in CSI
    //             which have the VRSAVE register class?
    // Adjust the frame index of the VRSAVE spill slot.
    for (unsigned i = 0, e = CSI.size(); i != e; ++i) {
      unsigned Reg = CSI[i].getReg();
    
      if (PPC::VRSAVERCRegisterClass->contains(Reg)) {
        int FI = CSI[i].getFrameIdx();

        FFI->setObjectOffset(FI, LowerBound + FFI->getObjectOffset(FI));
      }
    }
    
    LowerBound -= 4; // The VRSAVE save area is always 4 bytes long.
  }
  
  if (HasVRSaveArea) {
    // Insert alignment padding, we need 16-byte alignment.
    LowerBound = (LowerBound - 15) & ~(15);
    
    for (unsigned i = 0, e = VRegs.size(); i != e; ++i) {
      int FI = VRegs[i].getFrameIdx();
      
      FFI->setObjectOffset(FI, LowerBound + FFI->getObjectOffset(FI));
    }
  }
}

unsigned PPCRegisterInfo::getRARegister() const {
  return !Subtarget.isPPC64() ? PPC::LR : PPC::LR8;
}

unsigned PPCRegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  const TargetFrameInfo *TFI = MF.getTarget().getFrameInfo();

  if (!Subtarget.isPPC64())
    return TFI->hasFP(MF) ? PPC::R31 : PPC::R1;
  else
    return TFI->hasFP(MF) ? PPC::X31 : PPC::X1;
}

void PPCRegisterInfo::getInitialFrameState(std::vector<MachineMove> &Moves)
                                                                         const {
  // Initial state of the frame pointer is R1.
  MachineLocation Dst(MachineLocation::VirtualFP);
  MachineLocation Src(PPC::R1, 0);
  Moves.push_back(MachineMove(0, Dst, Src));
}

unsigned PPCRegisterInfo::getEHExceptionRegister() const {
  return !Subtarget.isPPC64() ? PPC::R3 : PPC::X3;
}

unsigned PPCRegisterInfo::getEHHandlerRegister() const {
  return !Subtarget.isPPC64() ? PPC::R4 : PPC::X4;
}

int PPCRegisterInfo::getDwarfRegNum(unsigned RegNum, bool isEH) const {
  // FIXME: Most probably dwarf numbers differs for Linux and Darwin
  return PPCGenRegisterInfo::getDwarfRegNumFull(RegNum, 0);
}

#include "PPCGenRegisterInfo.inc"
