import unittest
from python.verification.rv32i_reference import RV32IReference

class ReferenceTests(unittest.TestCase):
    def test_addi_lui_jalr_mask_and_ecall(self):
        m=RV32IReference()
        m.step((5<<20)|(0<<15)|(0<<12)|(1<<7)|0x13)
        self.assertEqual(m.read(1),5)
        m.step((1<<20)|(1<<15)|(0<<12)|(2<<7)|0x67)
        self.assertEqual(m.read(2),8)
        self.assertEqual(m.trap,(4,0))  # JALR clears bit zero but still requires 4-byte alignment
    def test_x0_and_ecall(self):
        m=RV32IReference(); m.step((123<<20)|0x13); self.assertEqual(m.read(0),0)
        m.step(0x73); self.assertEqual(m.trap,(4,11)); self.assertEqual(m.instret,1)
