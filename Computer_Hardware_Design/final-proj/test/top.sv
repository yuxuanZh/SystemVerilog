/**
 * The top level of the test
 */

module top;

   // Clock generator
   bit clk = 1;
   always #5 clk = ~clk;

   // Command to generate the VCD dump file that you open with DVE
   initial $vcdpluson;

   // Instantiate the testing modules
   ifc_test IFC_TEST(clk);
   bench BENCH (IFC_TEST.bench);
   superscalar DUT(IFC_TEST.dut);

endmodule
