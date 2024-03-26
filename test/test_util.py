from enum import Enum
class RxState(Enum):
    IDLE = 1
    START_BIT = 2
    BIT0 = 3
    BIT1 = 4
    BIT2 = 5
    BIT3 = 6
    BIT4 = 7
    BIT5 = 8
    BIT6 = 9
    BIT7 = 10
    STOP_BIT = 11

class UartRx:
    def __init__(self, clk_per_half_bit=5208):
        self.E_CLK_BIT = clk_per_half_bit * 2 - 1
        self.E_CLK_HALF_BIT = clk_per_half_bit - 1
        self.status = RxState.IDLE
        self.counter = 0
        self.next_counter = 0
        self.next_status = RxState.IDLE
        self.rdata = 0
        self.rdata_ready = 0
        self.ferr = 0

    def update_counter(self, reset):
        if not reset:
            self.counter = 0
        else:
            self.counter = self.next_counter
            if self.status == RxState.IDLE:  # IDLE
                self.next_counter = 0
            elif self.status == RxState.START_BIT:  # START_BIT
                if self.counter == self.E_CLK_HALF_BIT:
                    self.next_counter = 0
                else:
                    self.next_counter = self.counter + 1
            else:
                if self.counter == self.E_CLK_BIT:
                    self.next_counter = 0
                else:
                    self.next_counter = self.counter + 1

    def update_status_and_data(self, reset, rxd):
        if not reset:
            self.status = RxState.IDLE
            self.rdata = 0
            self.rdata_ready = 0
        else:
            self.status = self.next_status
            if self.status == RxState.IDLE:
                self.rdata_ready = 0
                if rxd == 0:
                    self.next_status = RxState.START_BIT
            elif self.status == RxState.START_BIT:
                if self.counter == self.E_CLK_HALF_BIT:
                    self.next_status = RxState.BIT0
            elif self.counter == self.E_CLK_BIT:
                if self.status == RxState.STOP_BIT:
                    self.next_status = RxState.IDLE
                    print("received 0x%02x" % self.rdata)
                    self.rdata_ready = 1
                    self.ferr = not rxd
                else:
                    self.rdata = (self.rdata >> 1) | (rxd << 7)
                    self.next_status = RxState(self.status.value + 1)

class TxState(Enum):
    IDLE = 0
    START_BIT = 1
    BIT0 = 2
    BIT1 = 3
    BIT2 = 4
    BIT3 = 5
    BIT4 = 6
    BIT5 = 7
    BIT6 = 8
    BIT7 = 9
    STOP_BIT = 10

class UartTx:
    def __init__(self, clk_per_half_bit=5208):
        self.E_CLK_BIT = clk_per_half_bit * 2 - 1
        self.status = TxState.IDLE
        self.txbuf = 0
        self.counter = 0
        self.next_counter = 0
        self.next_status = TxState.IDLE
        self.tx_busy = False
        self.txd = False

    def update_counter(self, rstn):
        if not rstn:
            self.counter = 0
        else:
            self.counter = self.next_counter
            if self.status == TxState.IDLE:
                self.next_counter = 0
            elif self.counter == self.E_CLK_BIT:
                self.next_counter = 0
            else:
                self.next_counter = self.counter + 1

    def update_status_and_data(self, rstn, tx_start, sdata):
        if not rstn:
            self.txbuf = 0
            self.status = TxState.IDLE
            self.tx_busy = False
        else:
            self.status = self.next_status
            if self.status == TxState.IDLE:
                if tx_start:
                    self.txbuf = sdata
                    self.next_status = TxState.START_BIT
                    self.tx_busy = True
            elif self.counter == self.E_CLK_BIT:
                if self.status == TxState.STOP_BIT:
                    self.next_status = TxState.IDLE
                    self.tx_busy = False
                    self.txbuf = 0
                elif self.status == TxState.START_BIT:
                    self.next_status = TxState.BIT0
                else:
                    self.txbuf >>= 1
                    self.next_status = TxState(self.status.value + 1)

        self.txd = (
            1 if self.status == TxState.IDLE else
            0 if self.status == TxState.START_BIT else
            1 if self.status == TxState.STOP_BIT else self.txbuf & 1
        )

class ServerState(Enum):
    IDLE = 0
    PROG_SEND = 3
    PROG_WAIT = 4
    WAIT_AA = 5
    DATA_SEND = 6
    DATA_WAIT = 7
    DONE = 8

import sys
import struct
from typing import Union

def num2bytes(n: Union[int, float], endian: str = '<'):
    """
    convert number to bytes

    Parameters
    ----------
    n      : int | float
        number to convert
    endian : str
        < -> little endian |
        > -> big endian

    Returns
    -------
    value : bytes
        4 bytes data with the specified endian
    """

    if isinstance(n, int):
        return struct.pack(endian + 'i', n)
    elif isinstance(n, float):
        return struct.pack(endian + 'f', n)
    else:
        print("illegal input: must be [int | float]")
        sys.exit()

class Server:
    def __init__(self, filename, inputs = [], data_filename = None, clk_per_half_bit=5208):
        self.rx = UartRx(clk_per_half_bit)
        self.tx = UartTx(clk_per_half_bit)
        self.txd = 1
        self.status = ServerState.IDLE
        self.send_data = 0
        self.next_send_data = 0
        self.tx_start = 0
        self.next_tx_start = 0
        self.rdata_ready = 0
        bytes = open(filename, "rb").read()
        self.byte_array = bytearray(num2bytes(len(bytes)) + bytes)
        self.addr = 0
        self.has_data = data_filename is not None or len(inputs) > 0
        if data_filename is not None:
            data_bytes = open(data_filename, "rb").read()
            self.data_byte_array = bytearray(data_bytes)
            self.data_addr = 0
        else:
            self.data_byte_array = []
            self.data_addr = 0
            for input in inputs:
                self.data_byte_array.extend(num2bytes(input))
        self.result = ""
                
    def update_rx(self, rstn, rxd):
        rdata = self.rx.rdata
        self.rdata_ready = self.rx.rdata_ready
        self.rx.update_status_and_data(rstn, rxd)
        self.rx.update_counter(rstn)
        return rdata, self.rdata_ready
    
    def update_tx(self, rstn, tx_start, sdata):
        txbusy = self.tx.tx_busy
        self.tx.update_counter(rstn)
        self.tx.update_status_and_data(rstn, tx_start, sdata)
        self.txd = self.tx.txd
        return txbusy

    def update(self, rstn, rxd):
        self.send_data = self.next_send_data
        self.tx_start = self.next_tx_start
        rdata, rdata_ready = self.update_rx(rstn, rxd)
        txbusy = self.update_tx(rstn, self.tx_start, self.send_data)
        if (self.status == ServerState.IDLE):
            if (rdata_ready and rdata == 0x99):
                    print("received 99")
                    self.status = ServerState.PROG_SEND
        elif (self.status == ServerState.PROG_SEND):
            self.next_tx_start = 1
            self.next_send_data = self.byte_array[self.addr]
            if (txbusy):
                self.status = ServerState.PROG_WAIT
                self.next_tx_start = 0
        elif (self.status == ServerState.PROG_WAIT):
            if (not txbusy):
                if (self.addr == len(self.byte_array) - 1):
                    self.status = ServerState.WAIT_AA
                else:
                    self.addr += 1
                    self.status = ServerState.PROG_SEND
        elif (self.status == ServerState.WAIT_AA):
            if (rdata_ready and rdata == 0xAA):
                print("received AA")
                if (self.has_data):
                    self.status = ServerState.DATA_SEND
                else:
                    self.status = ServerState.DONE
        elif (self.status == ServerState.DATA_SEND):
            self.next_tx_start = 1
            self.next_send_data = self.data_byte_array[self.data_addr]
            if (txbusy):
                self.status = ServerState.DATA_WAIT
                self.next_tx_start = 0            
        elif (self.status == ServerState.DATA_WAIT):
            if (not txbusy):
                if (self.data_addr == len(self.data_byte_array) - 1):
                    self.status = ServerState.DONE
                else:
                    self.data_addr += 1
                    self.status = ServerState.DATA_SEND
        elif (self.status == ServerState.DONE):
            if (rdata_ready):
                res = bytes([rdata]).decode("utf-8")
                self.result += res
                print("received output" + res)
