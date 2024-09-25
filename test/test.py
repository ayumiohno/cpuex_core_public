import cocotb
from cocotb.triggers import FallingEdge, Timer
from test_util import Server

async def reset(dut):
    dut.reset.value = 0
    for cycle in range(10):
        dut.clk.value = 1
        await Timer(1, units="ps")
        dut.clk.value = 0
        await Timer(1, units="ps")
        
async def generate_clock(dut, server):
    """Generate clock pulses."""
    dut.reset.value = 1
    dut.start.value = 1
    for cycle in range(1000000000):
        server.update(dut.reset.value, dut.txd.value)
        dut.rxd.value = server.txd
        dut.clk.value = 1
        await Timer(1, units="ps")
        dut.clk.value = 0
        await Timer(1, units="ps")
        
async def wait_until_end(dut):
    while dut.all_end.value == 0:
        await FallingEdge(dut.clk)        

# @cocotb.test()
# async def fib10test(dut):
#     server = Server(filename="data/fact.bin", clk_per_half_bit=8)
#     await reset(dut)
#     await cocotb.start(generate_clock(dut=dut, server=server))
#     await wait_until_end(dut)
#     dut._log.info("fact 5 is %08x", server.result[0])
#     assert server.result[0] == 89, "fib10 is not 89!"

# @cocotb.test()
# async def fib10test(dut):
#     server = Server(filename="data/fib10_rev.bin", clk_per_half_bit=8)
#     await reset(dut)
#     await cocotb.start(generate_clock(dut=dut, server=server))
#     await wait_until_end(dut)
#     dut._log.info("fib10 is %s", server.result[0])
#     assert server.result[0] == 89, "fib10 is not 89!"

# @cocotb.test()
# async def fib10iotest(dut):
#     # server = Server(filename="data/fib10_rev.bin", clk_per_half_bit=8)
#     server = Server(filename="data/fib_io.bin", inputs=[10], clk_per_half_bit=8)
#     await reset(dut)
#     await cocotb.start(generate_clock(dut=dut, server=server))
#     await wait_until_end(dut)
#     with open("fib_io_out.txt", "w") as f:
#         f.write(server.result)
#         f.close()
#     dut._log.info(f"fib10 is {server.result}")
#     assert server.result =='89', "fib10 is not 89!"

@cocotb.test()
async def fib10iotest(dut):
    server = Server(filename="data/mandelbrot.bin", clk_per_half_bit=8)
    await reset(dut)
    await cocotb.start(generate_clock(dut=dut, server=server))
    await wait_until_end(dut)
    with open("mandelbrot_out.txt", "w") as f:
        f.write(server.result)
        f.close()
    dut._log.info(f"fib10 is {server.result}")
    assert server.result =='89', "fib10 is not 89!"
