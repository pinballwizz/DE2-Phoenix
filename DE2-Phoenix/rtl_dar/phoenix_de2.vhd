---------------------------------------------------------------------------------
-- DE2-35 Top level for Phoenix by Dar (darfpga@aol.fr) (April 2016)
-- http://darfpga.blogspot.fr
--
-- Main features
--  PS2 keyboard input
--  wm8731 sound output
--  NO board SRAM used
--
-- Uses pll for 18MHz and 11MHz generation from 50MHz
--
-- Board switch :
--   0 - 7 : dip switch
--             0-1 : lives 3-6
--             3-2 : bonus life 30K-60K
--               4 : coin 1-2
--             6-5 : unkonwn
--               7 : upright-cocktail  
--   8 -10 : sound_select
--             0XX : all mixed (normal)
--             100 : sound1 only 
--             101 : sound2 only
--             110 : sound3 only
--             111 : melody only 
-- Board key :
--      0 : reset
--   
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity phoenix_de2 is
port(
 clock_50  : in std_logic;
 key       : in std_logic_vector(1 downto 0);
 sw        : in std_logic_vector(17 downto 0);

 ps2_clk : in std_logic;
 ps2_dat : inout std_logic;

 vga_r     : out std_logic_vector(9 downto 0);
 vga_g     : out std_logic_vector(9 downto 0);
 vga_b     : out std_logic_vector(9 downto 0);
 vga_clk   : out std_logic;
 vga_blank : out std_logic;
 vga_hs    : out std_logic;
 vga_vs    : out std_logic;
 vga_sync  : out std_logic;

 i2c_sclk : out std_logic;
 i2c_sdat : inout std_logic;
 
 aud_adclrck : out std_logic;
 aud_adcdat  : in std_logic;
 aud_daclrck : out std_logic;
 aud_dacdat  : out std_logic;
 aud_xck     : out std_logic;
 aud_bclk    : out std_logic
 
);
end phoenix_de2;
--------------------------------------------------------------------
architecture struct of phoenix_de2 is

 signal clock_36  : std_logic;
 signal clock_18  : std_logic;
 signal clock_12  : std_logic;
 signal clock_9   : std_logic;
 signal clock_6   : std_logic;
 signal slot      : std_logic_vector(2 downto 0) := (others => '0');
 
 signal r         : std_logic_vector(1 downto 0);
 signal g         : std_logic_vector(1 downto 0);
 signal b         : std_logic_vector(1 downto 0);
 signal vblank    : std_logic;
 signal vhb1		: std_logic;
 signal vhb2		: std_logic;
 signal blankn		: std_logic;
 signal csync     : std_logic;
 signal hsync     : std_logic;
 signal vsync     : std_logic;
 
 -- video signals   -- mod from somhic
 signal video_clk 		: std_logic;
 signal vga_g_i         : std_logic_vector(5 downto 0);   
 signal vga_r_i         : std_logic_vector(5 downto 0);   
 signal vga_b_i         : std_logic_vector(5 downto 0);   
 signal vga_r_o         : std_logic_vector(5 downto 0);   
 signal vga_g_o         : std_logic_vector(5 downto 0);   
 signal vga_b_o         : std_logic_vector(5 downto 0);   
 signal hsync_o         : std_logic;   
 signal vsync_o         : std_logic;   
 signal blankn_o        : std_logic;

 signal vga_r_c         : std_logic_vector(3 downto 0);
 signal vga_g_c         : std_logic_vector(3 downto 0);
 signal vga_b_c         : std_logic_vector(3 downto 0);
 signal vga_hs_c        : std_logic;
 signal vga_vs_c        : std_logic; 
 --
 signal audio       		: std_logic_vector(11 downto 0);
 signal sound_string 	: std_logic_vector(31 downto 0);
 signal reset        	: std_logic;
 
 alias  dip_switch   	: std_logic_vector(7 downto 0) is sw(7 downto 0);
 alias  audio_select 	: std_logic_vector(2 downto 0) is sw(10 downto 8);
 alias  reset_n      	: std_logic is key(0);
------------------------------------------------------------------------ 
  component scandoubler        -- mod from somhic
    port (
    clk_sys : in std_logic;
    scanlines : in std_logic_vector (1 downto 0);
    ce_x1 : in std_logic;
    ce_x2 : in std_logic;
    hs_in : in std_logic;
    vs_in : in std_logic;
    r_in : in std_logic_vector (5 downto 0);
    g_in : in std_logic_vector (5 downto 0);
    b_in : in std_logic_vector (5 downto 0);
    hs_out : out std_logic;
    vs_out : out std_logic;
    r_out : out std_logic_vector (5 downto 0);
    g_out : out std_logic_vector (5 downto 0);
    b_out : out std_logic_vector (5 downto 0)
  );
end component; 
------------------------------------------------------------------------ 
begin

reset <= not reset_n;

-----------------------------------------------
-- Clocks
-----------------------------------------------
-- pll
clocks : entity work.de2_clk36
port map(
 inclk0 => clock_50,
 c0 => clock_36,
 locked => open
);
------------------------------------------------
process (clock_36)
begin
 if rising_edge(clock_36) then
 
  clock_12  <= '0';
  clock_18  <= not clock_18;

  if slot = "101" then
   slot <= (others => '0');
  else
	slot <= std_logic_vector(unsigned(slot) + 1);
  end if;   
	
  if slot = "100" or slot = "001" then clock_6 <= not clock_6;	end if;
  if slot = "100" or slot = "001" then clock_12  <= '1';	end if;	

 end if;
end process;
------------------------------------------------------------------------
phoenix : entity work.phoenix
port map(
 clock_50     => clock_50,
 clock_11     => clock_12,
 reset        => reset,
 dip_switch   => dip_switch,
 ps2_clk      => ps2_clk,
 ps2_dat      => ps2_dat,
 video_r      => r,
 video_g      => g,
 video_b      => b,
 video_clk    => video_clk,
 video_csync  => csync,
 video_vblank  => vblank,
 video_hblank_bg  => vhb1,
 video_hblank_fg  => vhb2,
 video_hs     => hsync,
 video_vs     => vsync,
 audio_select => audio_select,
 audio        => audio
);
------------------------------------------------------------------------
vga_clk   <= clock_12;
vga_sync  <= '0';
vga_blank <= '1';

vga_r_i <= r & r & r; -- when blankn = '1' else "000000";
vga_g_i <= g & g & g; -- when blankn = '1' else "000000";
vga_b_i <= b & b & b; -- when blankn = '1' else "000000";
------------------------------------------------------------------------
-- vga scandoubler
scandoubler_inst :  scandoubler
  port map (
    clk_sys => clock_12,     --clock_18, video_clk i clock_36 no funciona
    scanlines => "00",       --(00-none 01-25% 10-50% 11-75%)
    ce_x1 => clock_6,     
    ce_x2 => '1',
    hs_in => hsync,
    vs_in => vsync,
    r_in => vga_r_i,
    g_in => vga_g_i,
    b_in => vga_b_i,
    hs_out => hsync_o,
    vs_out => vsync_o,
    r_out => vga_r_o,
    g_out => vga_g_o,
    b_out => vga_b_o
  );
------------------------------------------------------------------------
process (clock_12)
begin
		if rising_edge(clock_12) then
        --VGA adapt video to 4 for lite / 10 bits color only for de2
        vga_r  <= vga_r_o & "0000";
        vga_g  <= vga_g_o & "0000";
        vga_b  <= vga_b_o & "0000";
        vga_hs <= hsync_o;       
        vga_vs <= vsync_o; 	    	
			
		end if;
end process;
------------------------------------------------------------------------  
sound_string <= "0000" & audio & "0000" & audio;
------------------------------------------------------------------------
-- dac
------------------------------------------------------------------------
wm8731_dac : entity work.wm8731_dac
port map(
 clk18MHz => clock_18,
 sampledata => sound_string,
 i2c_sclk => i2c_sclk,
 i2c_sdat => i2c_sdat,
 aud_bclk => aud_bclk,
 aud_daclrck => aud_daclrck,
 aud_dacdat => aud_dacdat,
 aud_xck => aud_xck
); 
------------------------------------------------------------------------
end struct;
