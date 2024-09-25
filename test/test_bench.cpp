#include <iostream>
#include <verilated.h>
#include "Vtest_bench.h"

int time_counter = 0;

int main(int argc, char **argv)
{

  Verilated::commandArgs(argc, argv);

  // Instantiate DUT
  Vtest_bench *dut = new Vtest_bench();

  // Format
  dut->resetn = 1;
  dut->clk = 0;

  int cycle = 0;
  while (time_counter < 100000)
  {
    if ((time_counter % 5) == 0)
    {
      dut->clk = !dut->clk; // Toggle clock
      dut->rxd = 1;
    }
    if ((time_counter % 10) == 0)
    {
      // Cycle Count
      cycle++;
    }
    // if ((time_counter % 1000000) == 0) {
    //   dut->CPU_RESETN = 1;
    // } else {
    //   dut->CPU_RESETN = 0;
    // }

    dut->eval();

    time_counter++;
  }

  printf("Final Counter Value = %d\n", dut->out);

  dut->final();
}
