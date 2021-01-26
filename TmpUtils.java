package org.soaplab.clients;

public abstract class TmpUtils {


public static String prettyPrintHex(byte[] data) {


    int i = 0, j = 0;   // loop counters


    int line_addr = 0;  // memmory address printed on the left


    String line_to_print = "";


    if (data.length == 0) {


        return "";


    }


 


    StringBuilder _sbbuffer = new StringBuilder();


 


    //Loop through every input byte


    String _hexline = "";


    String _asciiline = "";


    for (i = 0, line_addr = 0; i < data.length; i++, line_addr++) {


        //Print the line numbers at the beginning of the line


        if ((i % 16) == 0) {


            if (i != 0) {


                _sbbuffer.append(_hexline);


                _sbbuffer.append("\t...\t");


                _sbbuffer.append(_asciiline + "\n");


            }


            _asciiline = "";


            _hexline = String.format("%#06x ", line_addr);


        }


 


        _hexline = _hexline.concat(String.format("%#04x ", data[i]));


        if (data[i] > 31 && data[i] < 127) {


            _asciiline = _asciiline.concat(String.valueOf((char) data[i]));


        } else {


            _asciiline = _asciiline.concat(".");


        }


    }


    // Handle the ascii for the final line, which may not be completely filled.


    if (i % 16 > 0) {


        for (j = 0; j < 16 - (i % 16); j++) {


            _hexline = _hexline.concat("     ");


        }


        _sbbuffer.append(_hexline);


        _sbbuffer.append("\t...\t");


        _sbbuffer.append(_asciiline);


    }


    return _sbbuffer.toString();


}
}
