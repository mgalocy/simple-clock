\m5_TLV_version 1d --inlineGen --noDirectiveComments --noline --clkAlways --bestsv --debugSigsYosys: tl-x.org
\m5
   use(m5-1.0)
   
   
   // #################################################################
   // #                                                               #
   // #  Simple Clock - Made by Joseph Hsu for Tiny Tapeout 6         #
   // #                                                               #
   // #################################################################
   
   // ========
   // Settings
   // ========
   
   //-------------------------------------------------------
   // Build Target Configuration
   //
   // To build within Makerchip for the FPGA or ASIC:
   //   o Use first line of file: \m5_TLV_version 1d --inlineGen --noDirectiveComments --noline --clkAlways --bestsv --debugSigsYosys: tl-x.org
   //set(MAKERCHIP, 0)
   // /var(target, FPGA)  // or ASIC
   
   set(MAKERCHIP, 0)
   var(my_design, tt_um_example)
   var(target, ASIC)  /// FPGA or ASIC
   //-------------------------------------------------------
   
   var(debounce_inputs, 0)         /// 1: Provide synchronization and debouncing on all input signals.
                                   /// 0: Don't provide synchronization and debouncing.
                                   /// m5_neq(m5_MAKERCHIP, 1): Debounce unless in Makerchip.
   var(second_cycs, m5_if(m5_MAKERCHIP, 5, 20000000))
   
   // ======================
   // Computed From Settings
   // ======================
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_eq(m5_MAKERCHIP, 1, 4'h03, 4'hff))

\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/35e36bd144fddd75495d4cbc01c4fc50ac5bde6f/tlv_lib/tiny_tapeout_lib.tlv'])


\TLV clock()
   |clock_time
      @0
         
         $reset = *reset || *ui_in[7];
         
         // ======================================================
         // $cycounter = the cycle count. This clock is set to a 
         // $frequency of 20mhz (1 mhz = 1 million) which means
         // it will count 20,000,000 cycles per second. You should
         // adjust your clock as needed for FPGA testing. For ASIC,
         // github.com/TinyTapeout/tt-rp2040-firmware#clock-configurations
         // should have instructions on how to configure the clock
         // 
         // ======================================================
         
         $frequency[24:0] = *ui_in[1] ? 25'd10000000:
                            *ui_in[2] ? 25'd12000000:
                            *ui_in[3] ? 25'd14000000:
                                        25'd20000000;
         
         
         $cycounter[24:0] =
            ($reset || >>1$cycounter == $frequency - 25'd1) ? 25'b0 :
             >>1$cycounter + 1;
         
         // ======================================================
         // $pulse = signal we set to pulse once per second
         // This is the driving pulse for other pieces of logic
         // ======================================================
         
         $pulse = ($cycounter == $frequency - 24'd1);
         
         // ======================================================
         // $ones_digit & $tens_digit = the right & left numbers 
         // respectively, shown on a 2 7-segment display. We set
         // the $ones_digit to count from numbers 0-9, and the
         // $tens_digit to count from 0-5. With this method, we
         // can display 0 - 59 seconds, before resetting. 
         // ======================================================
         
         $ones_digit[3:0] = ($reset) ? 4'b0:
                             !$pulse ? >>1$ones_digit :
                            (>>1$ones_digit == 4'b1001) ? 4'b0 :
                            >>1$ones_digit + 1;
         
         $tens_digit[3:0] = ($reset) ? 4'b0 :
                            !$pulse ? >>1$tens_digit :
                            (>>1$tens_digit == 4'b0101 && >>1$ones_digit == 4'b1001) ? 4'b0 :
                            (>>1$ones_digit == 4'b1001) ? >>1$tens_digit + 1 :
                            >>1$tens_digit;
         
         // ======================================================
         // For a 2 7-segment display, 7 bits control what part of
         // the "8" lights up. One Bit is used to switch rapidly
         // between the two displays. We tie the switching to a
         // variable called $show_tens, which as the name implies-
         // shows the tens value on the display:
         //          ([1]0,[2]2,[3]1,[4]5,[5]9,... etc.)
         // Now- we need some kind of signal to drive this switching
         // so we latched onto an arbitrary bit of $cycounter. 
         // ======================================================
         
         $show_tens = $cycounter[9];
         $digit[3:0] = $show_tens ? $tens_digit:
                                    $ones_digit;
         
         // ======================================================
         // [7]th bit of uo_out is what's flipping rapidly between
         // 0 and 1, to show 2 values- the $tens_digit value in 
         // the left display, and $ones_digit in the right display
         // ======================================================
         
         *uo_out[7] = $show_tens;
         
         // ======================================================
         // $showbits simply tells the display what hex values 
         // align with the display. For example, for a value of
         // '4' we turn on the 7th, 6th, 2nd, and 1st segment 
         // to form the shape of a '4'
         // ======================================================
         
         $showbits[6:0] =
            ($digit == 4'h00) ? 7'b0111111 :
            ($digit == 4'h01) ? 7'b0000110 :
            ($digit == 4'h02) ? 7'b1011011 :
            ($digit == 4'h03) ? 7'b1001111 :
            ($digit == 4'h04) ? 7'b1100110 :
            ($digit == 4'h05) ? 7'b1101101 :
            ($digit == 4'h06) ? 7'b1111101 :
            ($digit == 4'h07) ? 7'b0000111 :
            ($digit == 4'h08) ? 7'b1111111 :
            7'b1100111 ;
         
         *uo_out[6:0] = $showbits[6:0];
   // Note that pipesignals assigned here can be found under /fpga_pins/fpga.
   // Connect Tiny Tapeout outputs. Note that uio_ outputs are not available in the Tiny-Tapeout-3-based FPGA boards.
   //*uo_out = 8'b0;
   m5_if_neq(m5_target, FPGA, ['*uio_out = 8'b0;'])
   m5_if_neq(m5_target, FPGA, ['*uio_oe = 8'b0;'])
   
\SV

// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// ================================================

module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uo_out;
   m5_if_neq(m5_target, FPGA, ['logic [7:0]uio_in,  uio_out, uio_oe;'])
   logic [31:0] r;
   always @(posedge clk) r <= m5_if(m5_MAKERCHIP, ['$urandom()'], ['0']);
   assign ui_in = 8'b00000001;
   m5_if_neq(m5_target, FPGA, ['assign uio_in = 8'b0;'])
   logic ena = 1'b0;
   logic rst_n = ! reset;
   
   /*
   // Or, to provide specific inputs at specific times (as for lab C-TB) ...
   // BE SURE TO COMMENT THE ASSIGNMENT OF INPUTS ABOVE.
   // BE SURE TO DRIVE THESE ON THE B-PHASE OF THE CLOCK (ODD STEPS).
   // Driving on the rising clock edge creates a race with the clock that has unpredictable simulation behavior.
   initial begin
      #1  // Drive inputs on the B-phase.
         ui_in = 4'h0;
      #10 // Step 5 cycles, past reset.
         ui_in = 4'hFF;
      // ...etc.
   end
   */

   // Instantiate the Tiny Tapeout module.
   m5_user_module_name tt(.*);
   
   //assign passed = top.cyc_cnt > 60;
   assign failed = 1'b0;
endmodule


// Provide a wrapper module to debounce input signals if requested.
m5_if(m5_debounce_inputs, ['m5_tt_top(m5_my_design)'])
\SV


// =======================
// The Tiny Tapeout module
// =======================

module m5_user_module_name (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    m5_if_eq(m5_target, FPGA, ['/']['*'])   // The FPGA is based on TinyTapeout 3 which has no bidirectional I/Os (vs. TT6 for the ASIC).
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    m5_if_eq(m5_target, FPGA, ['*']['/'])
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
   wire reset = ! rst_n;
   
\TLV
   /* verilator lint_off UNOPTFLAT */
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()
   
   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , clock)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (top-to-bottom).
   m5+tt_input_labels_viz(['"Value[0]", "Value[1]", "Value[2]", "Value[3]", "Op[0]", "Op[1]", "Op[2]", "="'])

\SV
endmodule
