# Godot Named Binary Tag

## Introduction
Godot Named Binary Tag (GNBT) is a file format based on the idea of the Named Binary Tag used in Minecraft, but adapted for Godot Engine.
Using the GNBT class, you can serialize a Variant to save it to a file and later read it back.

For now, only the following data types are supported:

- Variant.Type.TYPE_BOOL
- Variant.Type.TYPE_INT
- Variant.Type.TYPE_FLOAT
- Variant.Type.TYPE_STRING
- Variant.Type.TYPE_STRING_NAME
- Variant.Type.TYPE_ARRAY
- Variant.Type.TYPE_DICTIONARY

The file can also be compressed or encrypted.

## How to write to a file
``` GDScript
func _ready()->void:
    #Create a new instance of the GNBT class
	var l_write_file:GNBT = GNBT.new()
	
    #Set the data to be saved
	l_write_file.data = { "data" : "test" }

    #Or any supported data type
    #l_write_file.data = "test"
    #l_write_file.data = 1
    #l_write_file.data = { "data" : "test", 1 : ["0", 1, 2, "3"] }
    #l_write_file.data = [ "0", 1, 3, 5 ]
	
    #Save the file
	l_write_file.save_file("user://saved_data.dat")
```

## How to read from a file
``` GDScript
func _ready()->void:
    #Create a new instance of the GNBT class
	var l_read_file:GNBT = GNBT.new()
	
    #Load the file
	l_read_file.load_file("user://saved_data.dat")
	
    #Print the data from the file (or save it wherever you want)
	print(l_read_file.data)
```