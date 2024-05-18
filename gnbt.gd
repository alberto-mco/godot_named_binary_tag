extends RefCounted

class_name GNBT

#Enumeraciones
enum GNBTCompressionMode { NONE, COMPRESSION_FASTLZ, COMPRESSION_DEFLATE, COMPRESSION_ZSTD, COMPRESSION_GZIP, COMPRESSION_BROTLI }

#Variables públicas
var data:Variant = null

#================================================================================
#Obtiene una cadena de texto
#================================================================================
func _get_string(p_file:FileAccess)->String:
	var l_size:int = p_file.get_32()
	var l_string_bytes:PackedByteArray
	
	#Recorremos el bucle hasta que no haya más carácteres
	while (l_size > 0):
		#Guardamos el carácter
		l_string_bytes.append(p_file.get_8())
		
		#Restamos un carácter pendiente de leer
		l_size -= 1
	
	return l_string_bytes.get_string_from_utf8()

#================================================================================
#Almacena una cadena de texto en el fichero
#================================================================================
func _store_string(p_file:FileAccess, p_value:String)->void:
	var l_string_bytes:PackedByteArray = p_value.to_utf8_buffer()
	
	#Guardamos el total de bytes que ocupa la cadena de texto
	p_file.store_32(l_string_bytes.size())
	
	#Guardamos la cadena de texto
	p_file.store_buffer(l_string_bytes)

#================================================================================
#Obtiene una cadena de texto
#================================================================================
func _get_string_name(p_file:FileAccess)->StringName:
	var l_size:int = p_file.get_32()
	var l_string_bytes:PackedByteArray
	
	#Recorremos el bucle hasta que no haya más carácteres
	while (l_size > 0):
		#Guardamos el carácter
		l_string_bytes.append(p_file.get_8())
		
		#Restamos un carácter pendiente de leer
		l_size -= 1
	
	return l_string_bytes.get_string_from_utf8()

#================================================================================
#Almacena una cadena de texto en el fichero
#================================================================================
func _store_string_name(p_file:FileAccess, p_value:StringName)->void:
	var l_string_bytes:PackedByteArray = p_value.to_utf8_buffer()
	
	#Guardamos el total de bytes que ocupa la cadena de texto
	p_file.store_32(l_string_bytes.size())
	
	#Guardamos la cadena de texto
	p_file.store_buffer(l_string_bytes)

#================================================================================
#Obtiene un array
#================================================================================
func _get_array(p_file:FileAccess)->Array:
	var l_result:Array = []
	var l_remaining_items:int = p_file.get_32()
	
	#Recorremos el bucle hasta obtener todos los elementos del array
	while (l_remaining_items > 0):
		#Obtenemos el tag
		var l_tag_id:int = p_file.get_16()
		
		#Obtenemos el valor
		l_result.append(_parse_tag(p_file, l_tag_id))
		
		#Restamos un elemento pendiente de procesar
		l_remaining_items -= 1
	
	return l_result

#================================================================================
#Almacena un array en el fichero
#================================================================================
func _store_array(p_file:FileAccess, p_values:Array)->void:
	var l_size:int = 0
	
	#Recorremos todos los items del array
	for l_value:Variant in p_values:
		var l_tag_id:int = typeof(l_value)
		
		#Comprobamos si es un item que se puede guardar
		if (GNBT.is_supported_variant_type(l_tag_id)):
			#Incrementamos el total de items que se guardarán
			l_size += 1
	
	#Guardamos el tamaño del array
	p_file.store_32(l_size)
	
	#Recorremos todos los items del array
	for l_value:Variant in p_values:
		var l_tag_id:int = typeof(l_value)
		
		#Comprobamos si es un item que se puede guardar
		if (GNBT.is_supported_variant_type(l_tag_id)):
			#Guardamos el identificador del tipo de dato
			p_file.store_16(l_tag_id)
			
			#Guardamos el valor
			_store_tag(p_file, l_tag_id, l_value)

#================================================================================
#Obtiene un diccionario
#================================================================================
func _get_dictionary(p_file:FileAccess)->Dictionary:
	var l_result:Dictionary = {}
	var l_end_of_dictionary:bool = false
	
	#Recorremos el bucle hasta llegar al final del diccionario
	while (l_end_of_dictionary == false):
		#Obtenemos el tag del valor
		var l_tag_id:int = p_file.get_16()
		
		#Comprobamos si hemos llegado al final del diccionario
		if (l_tag_id == Variant.Type.TYPE_NIL):
			#Establecemos el flag para indicar que hemos llegado al final del diccionario
			l_end_of_dictionary = true
		else:
			#Obtenemos el tag de la clave
			var l_key_tag_id:int = p_file.get_16()
			
			#Obtenemos la clave
			var l_key:Variant = _parse_tag(p_file, l_key_tag_id)
			
			#Obtenemos el valor
			l_result[l_key] = _parse_tag(p_file, l_tag_id)
	
	return l_result

#================================================================================
#Almacena un diccionario en el fichero
#================================================================================
func _store_dictionary(p_file:FileAccess, p_value:Dictionary)->void:
	#Recorremos todas las claves del diccionario
	for l_key:Variant in p_value.keys():
		var l_key_tag_id:int = typeof(l_key)
		
		#Comprobamos si soportamos la clave
		if (GNBT.is_supported_variant_type(l_key_tag_id)):
			var l_value_tag_id:int = typeof(p_value[l_key])
			
			#Comprobamos si soportamos el valor
			if (GNBT.is_supported_variant_type(l_value_tag_id)):
				#Guardamos el identificador del tipo de dato
				p_file.store_16(l_value_tag_id)
				
				#Guardamos el identificador del tipo de dato
				p_file.store_16(l_key_tag_id)
				
				#Guardamos la clave
				_store_tag(p_file, l_key_tag_id, l_key)
				
				#Guardamos el valor
				_store_tag(p_file, l_value_tag_id, p_value[l_key])
	
	#Guardamos el marcador de final de diccionario
	p_file.store_16(Variant.Type.TYPE_NIL)

#================================================================================
#Parsea un fichero NBT y vuelca la información en la variable "data"
#================================================================================
func _parse_tag(p_file:FileAccess, p_tag_id:int)->Variant:
	var l_result:Variant = null
	
	#Comprobamos el tipo de tag
	match (p_tag_id):
		Variant.Type.TYPE_BOOL:
			l_result = (p_file.get_8() > 0)
		Variant.Type.TYPE_INT:
			l_result = p_file.get_64()
		Variant.Type.TYPE_FLOAT:
			l_result = p_file.get_float()
		Variant.Type.TYPE_STRING:
			l_result = _get_string(p_file)
		Variant.Type.TYPE_STRING_NAME:
			l_result = _get_string_name(p_file)
		Variant.Type.TYPE_ARRAY:
			l_result = _get_array(p_file)
		Variant.Type.TYPE_DICTIONARY:
			l_result = _get_dictionary(p_file)
	
	return l_result

#================================================================================
#Guarda un tag en el fichero
#================================================================================
func _store_tag(p_file:FileAccess, p_tag_id:Variant.Type, p_value:Variant)->void:
	#Comprobamos el tipo de tag
	match (p_tag_id):
		Variant.Type.TYPE_BOOL:
			p_file.store_8(1 if p_value else 0)
		Variant.Type.TYPE_INT:
			p_file.store_64(p_value)
		Variant.Type.TYPE_FLOAT:
			p_file.store_float(p_value)
		Variant.Type.TYPE_STRING:
			_store_string(p_file, p_value)
		Variant.Type.TYPE_STRING_NAME:
			_store_string_name(p_file, p_value)
		Variant.Type.TYPE_ARRAY:
			_store_array(p_file, p_value)
		Variant.Type.TYPE_DICTIONARY:
			_store_dictionary(p_file, p_value)

#================================================================================
#Carga un fichero NBT
#================================================================================
func load_file(p_path:String, p_compression:GNBTCompressionMode = GNBTCompressionMode.NONE)->Error:
	var l_result:Error = Error.OK
	var l_file:FileAccess = null
	
	#Comprobamos el tipo de compresión
	if (p_compression == GNBTCompressionMode.NONE):
		#Abrimos el fichero
		l_file = FileAccess.open(p_path, FileAccess.READ)
	else:
		var l_compression_mode:FileAccess.CompressionMode = FileAccess.CompressionMode.COMPRESSION_DEFLATE
		
		match (p_compression):
			GNBTCompressionMode.COMPRESSION_FASTLZ:
				l_compression_mode = FileAccess.CompressionMode.COMPRESSION_FASTLZ
			GNBTCompressionMode.COMPRESSION_DEFLATE:
				l_compression_mode = FileAccess.CompressionMode.COMPRESSION_DEFLATE
			GNBTCompressionMode.COMPRESSION_ZSTD:
				l_compression_mode = FileAccess.CompressionMode.COMPRESSION_ZSTD
			GNBTCompressionMode.COMPRESSION_GZIP:
				l_compression_mode = FileAccess.CompressionMode.COMPRESSION_GZIP
			GNBTCompressionMode.COMPRESSION_BROTLI:
				l_compression_mode = FileAccess.CompressionMode.COMPRESSION_BROTLI
		
		#Abrimos el fichero comprimido
		l_file = FileAccess.open_compressed(p_path, FileAccess.READ, l_compression_mode)
	
	#Comprobamos si el fichero se ha abierto correctamente
	if (l_file != null):
		#Comprobamos si almenos hay 1 byte
		if (l_file.get_length() > 0):
			var l_root_tag_id:int = l_file.get_16()
			
			#Procesamos el primer tag
			data = _parse_tag(l_file, l_root_tag_id)
			
			#Cerramos el fichero
			l_file.close()
		else:
			l_result = Error.ERR_PARSE_ERROR
	else:
		#Obtenemos el error que generó la apertura del fichero
		l_result = l_file.get_error()
	
	return l_result

#================================================================================
#Carga un fichero NBT codificado
#================================================================================
func load_encrypted_file(p_path:String, p_password:String)->Error:
	var l_result:Error = Error.OK
	var l_file:FileAccess = null
	
	#Abrimos el fichero
	l_file = FileAccess.open_encrypted_with_pass(p_path, FileAccess.READ, p_password)
	
	#Comprobamos si el fichero se ha abierto correctamente
	if (l_file != null):
		#Comprobamos si almenos hay 1 byte
		if (l_file.get_length() > 0):
			var l_root_tag_id:int = l_file.get_16()
			
			#Procesamos el primer tag
			data = _parse_tag(l_file, l_root_tag_id)
			
			#Cerramos el fichero
			l_file.close()
		else:
			l_result = Error.ERR_PARSE_ERROR
	else:
		#Obtenemos el error que generó la apertura del fichero
		l_result = l_file.get_error()
	
	return l_result

#================================================================================
#Guarda el data en un fichero con formato NBT
#================================================================================
func save_file(p_path:String, p_compression:GNBTCompressionMode = GNBTCompressionMode.NONE)->Error:
	var l_result:Error = Error.OK
	var l_file:FileAccess = null
	
	#Comprobamos el tipo de compresión
	if (p_compression == GNBTCompressionMode.NONE):
		#Abrimos el fichero
		l_file = FileAccess.open(p_path, FileAccess.WRITE)
	else:
		var l_compression_mode:FileAccess.CompressionMode = FileAccess.CompressionMode.COMPRESSION_DEFLATE
		
		match (p_compression):
			GNBTCompressionMode.COMPRESSION_FASTLZ:
				l_compression_mode = FileAccess.CompressionMode.COMPRESSION_FASTLZ
			GNBTCompressionMode.COMPRESSION_DEFLATE:
				l_compression_mode = FileAccess.CompressionMode.COMPRESSION_DEFLATE
			GNBTCompressionMode.COMPRESSION_ZSTD:
				l_compression_mode = FileAccess.CompressionMode.COMPRESSION_ZSTD
			GNBTCompressionMode.COMPRESSION_GZIP:
				l_compression_mode = FileAccess.CompressionMode.COMPRESSION_GZIP
			GNBTCompressionMode.COMPRESSION_BROTLI:
				l_compression_mode = FileAccess.CompressionMode.COMPRESSION_BROTLI
		
		#Abrimos el fichero comprimido
		l_file = FileAccess.open_compressed(p_path, FileAccess.WRITE, l_compression_mode)
	
	#Comprobamos si el fichero se ha abierto correctamente
	if (l_file != null):
		var l_root_tag_id:Variant.Type = typeof(data)
		
		#Comprobamos si es un tipo de dato que podamos guardar en el fichero
		if (GNBT.is_supported_variant_type(l_root_tag_id)):
			#Guardamos el identificador del tipo de dato
			l_file.store_16(l_root_tag_id)
			
			#Guardamos el valor
			_store_tag(l_file, l_root_tag_id, data)
		
		#Cerramos el fichero
		l_file.close()
	else:
		#Obtenemos el error que generó la apertura del fichero
		l_result = l_file.get_error()
	
	return l_result

#================================================================================
#Guarda el data en un fichero con formato NBT pero codificado
#================================================================================
func save_encrypted_file(p_path:String, p_password:String)->Error:
	var l_result:Error = Error.OK
	var l_file:FileAccess = null
	
	#Abrimos el fichero
	l_file = FileAccess.open_encrypted_with_pass(p_path, FileAccess.WRITE, p_password)
	
	#Comprobamos si el fichero se ha abierto correctamente
	if (l_file != null):
		var l_root_tag_id:Variant.Type = typeof(data)
		
		#Comprobamos si es un tipo de dato que podamos guardar en el fichero
		if (GNBT.is_supported_variant_type(l_root_tag_id)):
			#Guardamos el identificador del tipo de dato
			l_file.store_16(l_root_tag_id)
			
			#Guardamos el valor
			_store_tag(l_file, l_root_tag_id, data)
		
		#Cerramos el fichero
		l_file.close()
	else:
		#Obtenemos el error que generó la apertura del fichero
		l_result = l_file.get_error()
	
	return l_result

#================================================================================
#Comprueba si el tipo de variant está soportado para guardarse dentro del fichero
#================================================================================
static func is_supported_variant_type(p_variant_type:Variant.Type)->bool:
	var l_result:bool = false
	
	#Comprobamos el tipo de variant
	match (p_variant_type):
		Variant.Type.TYPE_BOOL:
			l_result = true
		Variant.Type.TYPE_INT:
			l_result = true
		Variant.Type.TYPE_FLOAT:
			l_result = true
		Variant.Type.TYPE_STRING:
			l_result = true
		Variant.Type.TYPE_STRING_NAME:
			l_result = true
		Variant.Type.TYPE_ARRAY:
			l_result = true
		Variant.Type.TYPE_DICTIONARY:
			l_result = true
	
	return l_result
