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
		var l_tag_id:int = p_file.get_8()
		
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
			p_file.store_8(l_tag_id)
			
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
		var l_tag_id:int = p_file.get_8()
		
		#Comprobamos si hemos llegado al final del diccionario
		if (l_tag_id == Variant.Type.TYPE_NIL):
			#Establecemos el flag para indicar que hemos llegado al final del diccionario
			l_end_of_dictionary = true
		else:
			#Obtenemos el tag de la clave
			var l_key_tag_id:int = p_file.get_8()
			
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
				p_file.store_8(l_value_tag_id)
				
				#Guardamos el identificador del tipo de dato
				p_file.store_8(l_key_tag_id)
				
				#Guardamos la clave
				_store_tag(p_file, l_key_tag_id, l_key)
				
				#Guardamos el valor
				_store_tag(p_file, l_value_tag_id, p_value[l_key])
	
	#Guardamos el marcador de final de diccionario
	p_file.store_8(Variant.Type.TYPE_NIL)

#================================================================================
#Obtiene un Vector2i
#================================================================================
func _get_vector2i(p_file:FileAccess)->Vector2i:
	return Vector2i(p_file.get_64(), p_file.get_64())

#================================================================================
#Almacena un Vector2i en el fichero
#================================================================================
func _store_vector2i(p_file:FileAccess, p_value:Vector2i)->void:
	#Guardamos ambas coordenadas
	p_file.store_64(p_value.x)
	p_file.store_64(p_value.y)

#================================================================================
#Obtiene un Vector2
#================================================================================
func _get_vector2(p_file:FileAccess)->Vector2:
	return Vector2(p_file.get_double(), p_file.get_double())

#================================================================================
#Almacena un Vector2 en el fichero
#================================================================================
func _store_vector2(p_file:FileAccess, p_value:Vector2)->void:
	#Guardamos ambas coordenadas
	p_file.store_double(p_value.x)
	p_file.store_double(p_value.y)

#================================================================================
#Parsea un fichero NBT y vuelca la información en la variable "data"
#================================================================================
func _parse_tag(p_file:FileAccess, p_tag_id:int)->Variant:
	var l_result:Variant = null
	
	#Comprobamos el tipo de tag
	match (p_tag_id):
		Variant.Type.TYPE_BOOL: #1
			l_result = (p_file.get_8() > 0)
		Variant.Type.TYPE_INT: #2
			l_result = p_file.get_64()
		Variant.Type.TYPE_FLOAT: #3
			l_result = p_file.get_double()
		Variant.Type.TYPE_STRING: #4
			l_result = _get_string(p_file)
		Variant.Type.TYPE_VECTOR2: #5
			l_result = _get_vector2(p_file)
		Variant.Type.TYPE_VECTOR2I: #6
			l_result = _get_vector2i(p_file)
		Variant.Type.TYPE_STRING_NAME: #21
			l_result = _get_string_name(p_file)
		Variant.Type.TYPE_DICTIONARY: #27
			l_result = _get_dictionary(p_file)
		Variant.Type.TYPE_ARRAY: #28
			l_result = _get_array(p_file)
	
	return l_result

#================================================================================
#Guarda un tag en el fichero
#================================================================================
func _store_tag(p_file:FileAccess, p_tag_id:Variant.Type, p_value:Variant)->void:
	#Comprobamos el tipo de tag
	match (p_tag_id):
		Variant.Type.TYPE_BOOL: #1
			p_file.store_8(1 if p_value else 0)
		Variant.Type.TYPE_INT: #2
			p_file.store_64(p_value)
		Variant.Type.TYPE_FLOAT: #3
			p_file.store_double(p_value)
		Variant.Type.TYPE_STRING: #4
			_store_string(p_file, p_value)
		Variant.Type.TYPE_VECTOR2: #5
			_store_vector2(p_file, p_value)
		Variant.Type.TYPE_VECTOR2I: #6
			_store_vector2i(p_file, p_value)
		Variant.Type.TYPE_STRING_NAME: #21
			_store_string_name(p_file, p_value)
		Variant.Type.TYPE_DICTIONARY: #27
			_store_dictionary(p_file, p_value)
		Variant.Type.TYPE_ARRAY: #28
			_store_array(p_file, p_value)

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
			var l_root_tag_id:int = l_file.get_8()
			
			#Procesamos el primer tag
			data = _parse_tag(l_file, l_root_tag_id)
			
			#Cerramos el fichero
			l_file.close()
		else:
			l_result = Error.ERR_PARSE_ERROR
	else:
		#Marcamos el resultado como error
		l_result = Error.FAILED
	
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
			var l_root_tag_id:int = l_file.get_8()
			
			#Procesamos el primer tag
			data = _parse_tag(l_file, l_root_tag_id)
			
			#Cerramos el fichero
			l_file.close()
		else:
			l_result = Error.ERR_PARSE_ERROR
	else:
		#Marcamos el resultado como error
		l_result = Error.FAILED
	
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
		var l_root_tag_id:Variant.Type = (typeof(data) as Variant.Type)
		
		#Comprobamos si es un tipo de dato que podamos guardar en el fichero
		if (GNBT.is_supported_variant_type(l_root_tag_id)):
			#Guardamos el identificador del tipo de dato
			l_file.store_8(l_root_tag_id)
			
			#Guardamos el valor
			_store_tag(l_file, l_root_tag_id, data)
		
		#Cerramos el fichero
		l_file.close()
	else:
		#Marcamos el resultado como error
		l_result = Error.FAILED
	
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
		var l_root_tag_id:Variant.Type = (typeof(data) as Variant.Type)
		
		#Comprobamos si es un tipo de dato que podamos guardar en el fichero
		if (GNBT.is_supported_variant_type(l_root_tag_id)):
			#Guardamos el identificador del tipo de dato
			l_file.store_8(l_root_tag_id)
			
			#Guardamos el valor
			_store_tag(l_file, l_root_tag_id, data)
		
		#Cerramos el fichero
		l_file.close()
	else:
		#Marcamos el resultado como error
		l_result = Error.FAILED
	
	return l_result

#================================================================================
#Comprueba si el tipo de variant está soportado para guardarse dentro del fichero
#================================================================================
static func is_supported_variant_type(p_variant_type:Variant.Type)->bool:
	var l_result:bool = false
	
	#Comprobamos el tipo de variant
	match (p_variant_type):
		Variant.Type.TYPE_BOOL: #1 - La variable es de tipo bool.
			l_result = true
		Variant.Type.TYPE_INT: #2 - La variable es de tipo int.
			l_result = true
		Variant.Type.TYPE_FLOAT: #3 - Variable is of type float.
			l_result = true
		Variant.Type.TYPE_STRING: #4 - La variable es de tipo String.
			l_result = true
		Variant.Type.TYPE_VECTOR2: #5 - La variable es de tipo Vector2.
			l_result = true
		Variant.Type.TYPE_VECTOR2I: #6 - Variable is of type Vector2i.
			l_result = true
		Variant.Type.TYPE_STRING_NAME: #21 - Variable is of type StringName.
			l_result = true
		Variant.Type.TYPE_DICTIONARY: #27 - La variable es de tipo Dictionary.
			l_result = true
		Variant.Type.TYPE_ARRAY: #28 - La variable es de tipo Array.
			l_result = true
	
	#TO DO
	#Variant.Type.TYPE_NIL = 0 - La variable es null.
	#Variant.Type.TYPE_RECT2 = 7 - La variable es de tipo Rect2.
	#Variant.Type.TYPE_RECT2I = 8 - Variable is of type Rect2i.
	#Variant.Type.TYPE_VECTOR3 = 9 - La variable es de tipo Vector3.
	#Variant.Type.TYPE_VECTOR3I = 10 - Variable is of type Vector3i.
	#Variant.Type.TYPE_TRANSFORM2D = 11 - La variable es de tipo Transform2D.
	#Variant.Type.TYPE_VECTOR4 = 12 - Variable is of type Vector4.
	#Variant.Type.TYPE_VECTOR4I = 13 - Variable is of type Vector4i.
	#Variant.Type.TYPE_PLANE = 14 - La variable es de tipo Plane.
	#Variant.Type.TYPE_QUATERNION = 15 - Variable is of type Quaternion.
	#Variant.Type.TYPE_AABB = 16 - La variable es de tipo AABB.
	#Variant.Type.TYPE_BASIS = 17 - La variable es de tipo Basis.
	#Variant.Type.TYPE_TRANSFORM3D = 18 - Variable is of type Transform3D.
	#Variant.Type.TYPE_PROJECTION = 19 - Variable is of type Projection.
	#Variant.Type.TYPE_COLOR = 20 - La variable es de tipo Color.
	#Variant.Type.TYPE_NODE_PATH = 22 - La variable es de tipo NodePath.
	#Variant.Type.TYPE_RID = 23 - La variable es de tipo RID.
	#Variant.Type.TYPE_OBJECT = 24 - La variable es de tipo Object.
	#Variant.Type.TYPE_CALLABLE = 25 - Variable is of type Callable.
	#Variant.Type.TYPE_SIGNAL = 26 - Variable is of type Signal.
	#Variant.Type.TYPE_PACKED_BYTE_ARRAY = 29 - Variable is of type PackedByteArray.
	#Variant.Type.TYPE_PACKED_INT32_ARRAY = 30 - Variable is of type PackedInt32Array.
	#Variant.Type.TYPE_PACKED_INT64_ARRAY = 31 - Variable is of type PackedInt64Array.
	#Variant.Type.TYPE_PACKED_FLOAT32_ARRAY = 32 - Variable is of type PackedFloat32Array.
	#Variant.Type.TYPE_PACKED_FLOAT64_ARRAY = 33 - Variable is of type PackedFloat64Array.
	#Variant.Type.TYPE_PACKED_STRING_ARRAY = 34 - Variable is of type PackedStringArray.
	#Variant.Type.TYPE_PACKED_VECTOR2_ARRAY = 35 - Variable is of type PackedVector2Array.
	#Variant.Type.TYPE_PACKED_VECTOR3_ARRAY = 36 - Variable is of type PackedVector3Array.
	#Variant.Type.TYPE_PACKED_COLOR_ARRAY = 37 - Variable is of type PackedColorArray.
	#Variant.Type.TYPE_PACKED_VECTOR4_ARRAY = 38 - Variable is of type PackedVector4Array.
	#Variant.Type.TYPE_MAX = 39 - Representa el tamaño del enum Variant.Type.
	return l_result
