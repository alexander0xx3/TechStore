import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminProductosScreen extends StatefulWidget {
  const AdminProductosScreen({super.key});

  static const String routeName = '/productos';

  @override
  State<AdminProductosScreen> createState() => _AdminProductosScreenState();
}

class _AdminProductosScreenState extends State<AdminProductosScreen> {
  final CollectionReference _productosRef = FirebaseFirestore.instance.collection('Productos');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // --- ¡NUEVA FUNCIÓN! ---
  // Esta es la función que faltaba de tu 'pantalla_inicio.dart'
  String _convertirUrlDrive(String originalUrl) {
    if (originalUrl.contains('drive.google.com/file/d/')) {
      try {
        final parts = originalUrl.split('/d/');
        final fileId = parts[1].split('/')[0];
        // Devuelve la URL de contenido directo
        return 'https://drive.google.com/uc?export=view&id=$fileId';
      } catch (e) {
        // Si falla el parseo, devuelve la original
        return originalUrl;
      }
    }
    // Si no es un enlace de Google Drive, la devuelve tal cual
    return originalUrl;
  }

  Future<void> _eliminarProducto(String docId, String nombre) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de eliminar "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _productosRef.doc(docId).delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$nombre" eliminado correctamente'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioProducto([DocumentSnapshot? doc]) {
    final _formKey = GlobalKey<FormState>();
    final _nombreController = TextEditingController();
    final _precioController = TextEditingController();
    final _categoriaController = TextEditingController();
    final _imagenController = TextEditingController();
    final _descripcionController = TextEditingController();
    
    String? editingDocId = doc?.id;
    String dialogTitle = 'Agregar Nuevo Producto';

    // --- ¡NUEVO! Notificador para la vista previa ---
    final imagePreviewNotifier = ValueNotifier<String>('');

    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      dialogTitle = 'Editando Producto';
      _nombreController.text = data['nombre'] ?? '';
      _precioController.text = (data['precio'] as num? ?? 0.0).toString();
      _categoriaController.text = data['categoria'] ?? '';
      _imagenController.text = data['imagen'] ?? '';
      _descripcionController.text = data['descripcion'] ?? '';
      imagePreviewNotifier.value = data['imagen'] ?? ''; // Asigna valor inicial
    }

    // --- ¡NUEVO! Listener para actualizar la vista previa ---
    _imagenController.addListener(() {
      imagePreviewNotifier.value = _imagenController.text;
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dialogTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColorDark, // Coincidir con el tema
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // --- ¡MODIFICADO! Quitamos el Expanded ---
              Flexible( // Usamos Flexible para que el SingleChildScrollView no colapse
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nombreController,
                          label: 'Nombre del Producto',
                          icon: Icons.shopping_bag,
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _precioController,
                          label: 'Precio',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          prefixText: 'S/ ',
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _categoriaController,
                          label: 'Categoría',
                          icon: Icons.category,
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _imagenController,
                          label: 'URL de Imagen',
                          icon: Icons.image,
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // --- ¡MODIFICADO! Vista previa de la imagen ---
                        ValueListenableBuilder<String>(
                          valueListenable: imagePreviewNotifier,
                          builder: (context, imageUrl, child) {
                            if (imageUrl.isEmpty) return const SizedBox.shrink();
                            
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Vista previa:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[400]!),
                                      ),
                                      // --- ¡CORREGIDO! Usamos _buildImagePreview ---
                                      child: _buildImagePreview(imageUrl),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _descripcionController,
                          label: 'Descripción',
                          icon: Icons.description,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        
                        final data = {
                          'nombre': _nombreController.text.trim(),
                          'precio': double.tryParse(_precioController.text.trim()) ?? 0.0,
                          'categoria': _categoriaController.text.trim(),
                          'imagen': _imagenController.text.trim(),
                          'descripcion': _descripcionController.text.trim(),
                          'esDestacado': false,
                          'fechaActualizacion': FieldValue.serverTimestamp(),
                        };

                        try {
                          if (editingDocId == null) {
                            await _productosRef.add(data);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Producto agregado correctamente'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            await _productosRef.doc(editingDocId).update(data);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Producto actualizado correctamente'),
                                backgroundColor: Colors.blue,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          Navigator.of(context).pop();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al guardar: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        editingDocId == null ? 'Agregar Producto' : 'Actualizar',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColorDark), // Coincidir con el tema
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColorDark, width: 2),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              'Sin imagen',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // --- ¡CORREGIDO! Convertimos la URL antes de mostrarla ---
    final String convertedUrl = _convertirUrlDrive(imageUrl);

    return Image.network(
      convertedUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 30, color: Colors.grey),
              SizedBox(height: 4),
              Text(
                'Error al cargar', // Texto de la captura
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }

    // --- ¡CORREGIDO! Convertimos la URL antes de mostrarla ---
    final String convertedUrl = _convertirUrlDrive(imageUrl);

    return Image.network(
      convertedUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nombre = data['nombre'] ?? 'Sin nombre';
    final precio = (data['precio'] as num? ?? 0.0).toStringAsFixed(2);
    final categoria = data['categoria'] ?? 'Sin categoría';
    final imagen = data['imagen'] ?? ''; // La URL original
    final descripcion = data['descripcion'] ?? '';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen del producto
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 140,
              color: Colors.grey[100],
              // --- ¡CORREGIDO! Pasamos la URL original a _buildImageWidget ---
              // (La función _buildImageWidget se encargará de convertirla)
              child: _buildImageWidget(imagen),
            ),
          ),
          
          // Contenido de la tarjeta
          Expanded( // Añadimos Expanded para que el contenido llene el espacio
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribuye el espacio
                children: [
                  // --- Sección Superior (Nombre y Categoría) ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          categoria,
                          style: TextStyle(
                            color: Theme.of(context).primaryColorDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (descripcion.isNotEmpty) ...[
                        Text(
                          descripcion,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                  
                  // --- Sección Inferior (Precio y Acciones) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Precio',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'S/ $precio',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Theme.of(context).primaryColorDark,
                            ),
                          ),
                        ],
                      ),
                      
                      // Botones de acción
                      Row(
                        children: [
                          // Botón Editar
                          SizedBox( // Tamaño consistente
                            width: 40, height: 40,
                            child: IconButton.filled(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _mostrarFormularioProducto(doc),
                              tooltip: 'Editar producto',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Botón Eliminar
                          SizedBox( // Tamaño consistente
                            width: 40, height: 40,
                            child: IconButton.filled(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _eliminarProducto(doc.id, nombre),
                              tooltip: 'Eliminar producto',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Productos',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).primaryColorDark, // Coincidir con el tema
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Administra los productos de tu tienda',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorDark, // Coincidir con el tema
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _productosRef.snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return Text(
                        '$count productos',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Barra de búsqueda
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Buscar productos por nombre o categoría...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Grid de productos
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // --- ¡¡¡AQUÍ ESTÁ LA CORRECCIÓN!!! ---
                // Quité el .orderBy('fechaActualizacion', descending: true)
                stream: _productosRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColorDark),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text('No se pudieron cargar los productos'),
                    );
                  }

                  var docs = snapshot.data!.docs;
                  
                  // Aplicar filtro de búsqueda
                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nombre = data['nombre']?.toString().toLowerCase() ?? '';
                      final categoria = data['categoria']?.toString().toLowerCase() ?? '';
                      return nombre.contains(_searchQuery.toLowerCase()) ||
                             categoria.contains(_searchQuery.toLowerCase());
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.inventory_2 : Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No hay productos' : 'No se encontraron productos',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'Presiona el botón + para agregar tu primer producto'
                              : 'Intenta con otros términos de búsqueda',
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8, // Ajustado para dar más espacio
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) => _buildProductCard(docs[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioProducto(),
        backgroundColor: Theme.of(context).primaryColorDark, // Coincidir con el tema
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
        tooltip: 'Agregar nuevo producto',
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}