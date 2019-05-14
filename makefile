
# Makefile script for building mixed C & assembly programs CPSC359/RPi3
# by Mohamad Elzohbi.


# Compiled object files directory.
BUILD = build/

# Source files directory.
SOURCE = source/

# Object files to be generated from source.
OBJECTS := $(patsubst $(SOURCE)%.s,$(BUILD)%.o,$(wildcard $(SOURCE)*.s))
COBJECTS := $(patsubst $(SOURCE)%.c,$(BUILD)%.o,$(wildcard $(SOURCE)*.c))

# Rule to make the executable files.
main: $(OBJECTS) $(COBJECTS)
	gcc -lwiringPi -o main $(OBJECTS) $(COBJECTS)

# Rule to make the object files.
$(BUILD)%.o: $(SOURCE)%.s
	as --gstabs -I $(SOURCE) $< -o $@

$(BUILD)%.o: $(SOURCE)%.c
	gcc -g -c -O1 -Wall -I $(SOURCE) $< -o $@

# Rule to clean files
clean: 
	-rm -f $(BUILD)*.o main


