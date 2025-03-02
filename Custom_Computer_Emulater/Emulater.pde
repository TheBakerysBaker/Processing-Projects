final int halt = 0, move = 1, compare = 2, jump = 3, jumpG = 4, jumpGE = 5, jumpL = 6, jumpLE = 7, jumpE = 8, jumpNE = 9, add = 10, sub = 11, mult = 12, div = 13,
  and = 14, or = 15, xor = 16, not = 17, bsl = 18, bsr = 19, push = 20, pop = 21, call = 22, ret = 23, mod = 24, addF = 25, subF = 26, multF = 27, divF = 28, compareF = 29, FtoI = 30, ItoF = 31;
final String[] tokens = {"halt", "move", "compare", "jump", "jumpG", "jumpGE", "jumpL", "jumpLE", "jumpE", "jumpNE", "add", "sub", "mult", "div", "and", "or", "xor", "not", "<<", ">>", "push", "pop", "call", "return", "mod",
  "addF", "subF", "multF", "divF", "compareF", "FtoI", "ItoF"};
final String[] register_tokens = {"PC", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "Z", "R", "SP"};
final int stack_length = 4096;
final int variables_length = 64;
final int code_length = 4096 * 4;
final int graphics_length = 32400;
final int variables_start = stack_length;
final int code_start = variables_start + variables_length;
final int graphics_start = code_start + code_length;
final int RAM_start = graphics_start + graphics_length;
final int PC = 0, SP = 15;
final int Literal = 0, Register = 1, Pointer = 2;
final int BW_L = 0, BW_M = 1, BW_S = 2, BW_T = 3, RGB_L = 4;
final int bits = 16;
final int max_value = (1 << bits) - 1;
int code_index = code_start;

import java.util.Scanner;

Emulator computer;
Display ED;
C_Compiler CC;
Assembly_Compiler AC;
PImage a;
int W = 180;
int H = 180;
PImage computer_img;
PGraphics display, computer_img_scaled;

void settings()
{
  size(1500, 800, P2D);
}

void setup()
{
  computer = new Emulator((short)W, (short)H);
  CC = new C_Compiler("C_Code.txt");
  AC = new Assembly_Compiler("Code.txt", computer);
  a = loadImage("C:\\Users\\reyno\\Downloads\\font\\mbf_small_00_black_bg.png");
  int count = 0;
  for (int y = 0; y < 16; y ++)
  {
    for (int x = 0; x < 16; x ++)
    {
      for (int j = 0; j < 7; j ++)
      {
        for (int i = 0; i < 7; i ++)
        {
          color c = a.get(x * 7 + i, y * 7 + j);
          computer.memory[RAM_start + count] = (short)(red(c) > 0 ? 0xFFFF : 0);
          count ++;
        }
      }
    }
  }
  ED = new Display(computer);
  computer.do_print(false);
  //computer.run(222);
  computer.start();
  computer_img = loadImage("ComputerToEmulate.png");
  float s = height / (float)computer_img.width;
  computer_img_scaled = createGraphics(height, height);
  computer_img_scaled.beginDraw();
  computer_img_scaled.noStroke();
  for (int j = 0; j < computer_img.height; j ++)
  {
    for (int i = 0; i < computer_img.width; i ++)
    {
      computer_img_scaled.fill(computer_img.get(i, j));
      computer_img_scaled.rect(i * s, j * s, s, s);
    }
  }
  computer_img_scaled.endDraw();
}

void draw()
{
  background(75);
  image(computer_img_scaled, 0, 0);

  pushMatrix();
  translate(height, 0);

  fill(175);
  rect(50, 50, width - computer_img_scaled.width - 100, 50);
  float x = map(variables_start, 0, max_value, 50, 50 + width - computer_img_scaled.width - 100);
  line(x, 50, x, 100);
  x = map(code_start, 0, max_value, 50, 50 + width - computer_img_scaled.width - 100);
  line(x, 50, x, 100);
  x = map(graphics_start, 0, max_value, 50, 50 + width - computer_img_scaled.width - 100);
  line(x, 50, x, 100);
  x = map(RAM_start, 0, max_value, 50, 50 + width - computer_img_scaled.width - 100);
  line(x, 50, x, 100);

  x = map(code_index, 0, max_value, 50, 50 + width - computer_img_scaled.width - 100);
  line(x, 50, x, 100);

  x = map(short_to_int(computer.registers[PC]) + code_start, 0, max_value, 50, 50 + width - computer_img_scaled.width - 100);
  line(x, 50, x, 100);

  x = map(short_to_int(computer.registers[SP]), 0, max_value, 50, 50 + width - computer_img_scaled.width - 100);
  
  textSize(14);
  
  for(int i = 0; i < register_tokens.length; i ++)
  {
    text("Register " + register_tokens[i] + ": " + computer.registers[i], 50, 120 + i * 16);
  }
  
  text("HALT", 300, 300);
  text("STEP", 340, 300);
  
  translate(0, 500);
  fill(175);
  rect(0, 0, width, height);
  translate(0, 20);
  textAlign(LEFT, TOP);
  fill(0);
  textSize(25);
  text("--=memory addresses=--", 50, 0);
  textSize(17);
  text("display width: " + variables_start, 50, 40);
  text("display height: " + variables_start + 1, 50, 60);
  text("display type: " + variables_start + 2, 50, 80);
  text("graphics start: " + graphics_start, 50, 100);
  text("stack start: " + (stack_length - 1), 50, 120);
  text("ascii graphics start: " + RAM_start, 50, 140);
  popMatrix();
}

int short_to_int(short v)
{
  return ((1<<bits)-1) & v;
}

float toFloat( int hbits )
{
  int mant = hbits & 0x03ff;            // 10 bits mantissa
  int exp =  hbits & 0x7c00;            // 5 bits exponent
  if ( exp == 0x7c00 )                   // NaN/Inf
    exp = 0x3fc00;                    // -> NaN/Inf
  else if ( exp != 0 )                   // normalized value
  {
    exp += 0x1c000;                   // exp - 15 + 127
    if ( mant == 0 && exp > 0x1c400 )  // smooth transition
      return Float.intBitsToFloat( ( hbits & 0x8000 ) << 16
        | exp << 13 | 0x3ff );
  } else if ( mant != 0 )                  // && exp==0 -> subnormal
  {
    exp = 0x1c400;                    // make it normal
    do {
      mant <<= 1;                   // mantissa * 2
      exp -= 0x400;                 // decrease exp by 1
    } while ( ( mant & 0x400 ) == 0 ); // while not normal
    mant &= 0x3ff;                    // discard subnormal bit
  }                                     // else +/-0 -> +/-0
  return Float.intBitsToFloat(          // combine all parts
    ( hbits & 0x8000 ) << 16          // sign  << ( 31 - 15 )
    | ( exp | mant ) << 13 );         // value << ( 23 - 10 )
}

int fromFloat( float fval )
{
  int fbits = Float.floatToIntBits( fval );
  int sign = fbits >>> 16 & 0x8000;          // sign only
  int val = ( fbits & 0x7fffffff ) + 0x1000; // rounded value

  if ( val >= 0x47800000 )               // might be or become NaN/Inf
  {                                     // avoid Inf due to rounding
    if ( ( fbits & 0x7fffffff ) >= 0x47800000 )
    {                                 // is or must become NaN/Inf
      if ( val < 0x7f800000 )        // was value but too large
        return sign | 0x7c00;     // make it +/-Inf
      return sign | 0x7c00 |        // remains +/-Inf or NaN
        ( fbits & 0x007fffff ) >>> 13; // keep NaN (and Inf) bits
    }
    return sign | 0x7bff;             // unrounded not quite Inf
  }
  if ( val >= 0x38800000 )               // remains normalized value
    return sign | val - 0x38000000 >>> 13; // exp - 127 + 15
  if ( val < 0x33000000 )                // too small for subnormal
    return sign;                      // becomes +/-0
  val = ( fbits & 0x7fffffff ) >>> 23;  // tmp exp for subnormal calc
  return sign | ( ( fbits & 0x7fffff | 0x800000 ) // add subnormal bit
    + ( 0x800000 >>> val - 102 )     // round depending on cut off
    >>> 126 - val );   // div by 2^(1-(exp-127+15)) and >> 13 | exp=0
}

float toBigFloat(final short half)
{
  switch((int)half)
  {
  case 0x0000 :
    return 0.0f;
  case 0x8000 :
    return -0.0f;
  case 0x7c00 :
    return Float.POSITIVE_INFINITY;
  case 0xfc00 :
    return Float.NEGATIVE_INFINITY;
    // @TODO: support for NaN ?
  default :
    return Float.intBitsToFloat((( half & 0x8000 )<<16 ) | ((( half & 0x7c00 ) + 0x1C000 )<<13 ) | (( half & 0x03FF )<<13 ));
  }
}

short toHalfFloat(final float v)
{
  if (Float.isNaN(v)) throw new UnsupportedOperationException("NaN to half conversion not supported!");
  if (v == Float.POSITIVE_INFINITY) return(short)0x7c00;
  if (v == Float.NEGATIVE_INFINITY) return(short)0xfc00;
  if (v == 0.0f) return(short)0x0000;
  if (v == -0.0f) return(short)0x8000;
  if (v > 65504.0f) return 0x7bff;  // max value supported by half float
  if (v < -65504.0f) return(short)( 0x7bff | 0x8000 );
  if (v > 0.0f && v < 5.96046E-8f) return 0x0001;
  if (v < 0.0f && v > -5.96046E-8f) return(short)0x8001;

  final int f = Float.floatToIntBits(v);

  return(short)((( f>>16 ) & 0x8000 ) | (((( f & 0x7f800000 ) - 0x38000000 )>>13 ) & 0x7c00 ) | (( f>>13 ) & 0x03ff ));
}
