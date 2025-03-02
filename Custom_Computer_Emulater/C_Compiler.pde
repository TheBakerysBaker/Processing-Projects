class C_Compiler
{

  C_Compiler(String file_path)
  {
    String file = new Scanner(new File("filename")).useDelimiter("\\Z").next();
    
    ArrayList<Token> tokens = tokenize(file);
  }
}

class C_function
{

  String name;


  C_function(String n)
  {
    name = n;
  }
}

final String[] C_Split_Tokens = {" ", "(", ")", "{", "}"};

ArrayList<Token> tokenize(String file)
{
  ArrayList<Token> tokens = new ArrayList<Token>();
  
  for(int i = 0; i < file.length(); i ++)
  {
    char c = file.charAt(i);
  }
  
  return tokens;
}

class Token
{
  
  String str;
  int type;
  
}
