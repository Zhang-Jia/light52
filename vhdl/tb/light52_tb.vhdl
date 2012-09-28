--------------------------------------------------------------------------------
-- light52_tb.vhdl --
--------------------------------------------------------------------------------
-- Copyright (C) 2011 Jose A. Ruiz
--                                                              
-- This source file may be used and distributed without         
-- restriction provided that this copyright statement is not    
-- removed from the file and that any derivative work contains  
-- the original copyright notice and the associated disclaimer. 
--                                                              
-- This source file is free software; you can redistribute it   
-- and/or modify it under the terms of the GNU Lesser General   
-- Public License as published by the Free Software Foundation; 
-- either version 2.1 of the License, or (at your option) any   
-- later version.                                               
--                                                              
-- This source is distributed in the hope that it will be       
-- useful, but WITHOUT ANY WARRANTY; without even the implied   
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
-- PURPOSE.  See the GNU Lesser General Public License for more 
-- details.                                                     
--                                                              
-- You should have received a copy of the GNU Lesser General    
-- Public License along with this source; if not, download it   
-- from http://www.opencores.org/lgpl.shtml
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;

use work.light52_pkg.all;
use work.obj_code_pkg.all;
use work.light52_tb_pkg.all;
use work.txt_util.all;

entity light52_tb is
end;


architecture testbench of light52_tb is

-- FIXME these should be in parameter package

-- Simulated clock period is the same as the usual target, the DE-1 board
constant T : time := 20 ns; -- 50MHz
constant SIMULATION_LENGTH : integer := 400000;

-- We'll simulate the full code space; the instruction tester will need to test 
-- jumps and calls to different pages.
constant ROM_SIZE : natural := 65536;

signal done :               std_logic := '0';


-- MPU interface 
signal clk :                std_logic := '0';
signal reset :              std_logic := '1';

signal p0_out :             std_logic_vector(7 downto 0);
signal p1_out :             std_logic_vector(7 downto 0);
signal p2_in :              std_logic_vector(7 downto 0);
signal p3_in :              std_logic_vector(7 downto 0);

signal external_irq :       std_logic_vector(7 downto 0);

signal txd, rxd :           std_logic;

--------------------------------------------------------------------------------
-- Logging signals

-- Log file
file log_file: TEXT open write_mode is "hw_sim_log.txt";
-- Console output log file
file con_file: TEXT open write_mode is "hw_sim_console_log.txt";
-- Info record needed by the logging fuctions
signal log_info :           t_log_info;

begin

---- UUT instantiation ---------------------------------------------------------

uut: entity work.light52_mcu
    generic map (
        CODE_ROM_SIZE => ROM_SIZE,
        OBJ_CODE => object_code
    )
    port map (
        clk             => clk,
        reset           => reset,
        
        txd             => txd,
        rxd             => rxd,
        
        external_irq    => external_irq,
                
        p0_out          => p0_out,
        p1_out          => p1_out,
        p2_in           => p2_in,
        p3_in           => p3_in
    );
    
    -- UART is looped back in the test bench.
    rxd <= txd;
    
    -- I/O ports are looped back and otherwise unused.
    p2_in <= p0_out;
    p3_in <= p1_out;
    
    -- External IRQ inputs are tied to port P1 for test purposes
    external_irq <= p1_out;

    ---- Master clock: free running clock used as main module clock ------------
    run_master_clock:
    process(done, clk)
    begin
        if done = '0' then
            clk <= not clk after T/2;
        end if;
    end process run_master_clock;


    ---- Main simulation process: reset MCU and wait for fixed period ----------

    drive_uut:
    process
    begin
        -- Leave reset asserted for a few clock cycles...
        reset <= '1';
        wait for T*4;
        reset <= '0';
        
        -- ...and wait for the test to hit a termination condition (evaluated by
        -- function log_cpu_activity) or to just timeout.
        wait for T*SIMULATION_LENGTH;

        -- If we arrive here, the simulation timed out (termination conditions
        -- trigger a failed assertion).
        -- So print a timeout message and quit.
        print("TB timed out.");
        done <= '1';
        wait;
        
    end process drive_uut;


    -- Logging process: launch logger functions --------------------------------
    log_execution:
    process
    begin
        -- Log cpu activity until done='1'.
        log_cpu_activity(clk, reset, done, "/uut",
                         log_info, ROM_SIZE, "log_info", 
                         X"0000", log_file, con_file);
        
        -- Flush console log file when finished.
        log_flush_console(log_info, con_file);
        
        wait;
    end process log_execution;

end architecture testbench;
