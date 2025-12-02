import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminProductosScreen extends StatefulWidget {
  const AdminProductosScreen({super.key});

  static const String routeName = '/productos';

  @override
  State<AdminProductosScreen> createState() => _AdminProductosScreenState();
}

class _AdminProductosScreenState extends State<AdminProductosScreen> {
  final CollectionReference _productosRef =
      FirebaseFirestore.instance.collection('Productos');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Función para convertir URLs de Google Drive - Versión WEB (Proxy)
  String _convertirUrlDrive(String originalUrl) {
    if (originalUrl.contains('drive.google.com/file/d/')) {
      try {
        final parts = originalUrl.split('/d/');
        final fileId = parts[1].split('/')[0];
        // Usamos proxy para evitar CORS en web
        return 'https://wsrv.nl/?url=https://drive.google.com/uc?id=$fileId';
      } catch (e) {
        return originalUrl;
      }
    }
    return originalUrl;
  }

  Future<void> _eliminarProducto(String docId, String nombre) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de eliminar "$nombre"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _productosRef.doc(docId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"$nombre" eliminado'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
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
    String dialogTitle = 'Nuevo Producto';
    final imagePreviewNotifier = ValueNotifier<String>('');

    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      dialogTitle = 'Editar Producto';
      _nombreController.text = data['nombre'] ?? '';
      _precioController.text = (data['precio'] as num? ?? 0.0).toString();
      _categoriaController.text = data['categoria'] ?? '';
      _imagenController.text = data['imagen'] ?? '';
      _descripcionController.text = data['descripcion'] ?? '';
      imagePreviewNotifier.value = data['imagen'] ?? '';
    }

    _imagenController.addListener(() {
      imagePreviewNotifier.value = _imagenController.text;
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dialogTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nombreController,
                          label: 'Nombre del Producto',
                          icon: Icons.shopping_bag_outlined,
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _precioController,
                                label: 'Precio',
                                icon: Icons.attach_money,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v!.isEmpty ? 'Requerido' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _categoriaController,
                                label: 'Categoría',
                                icon: Icons.category_outlined,
                                validator: (v) =>
                                    v!.isEmpty ? 'Requerido' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _imagenController,
                          label: 'URL de Imagen',
                          icon: Icons.image_outlined,
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<String>(
                            valueListenable: imagePreviewNotifier,
                            builder: (context, imageUrl, child) {
                              if (imageUrl.isEmpty)
                                return const SizedBox.shrink();

                              return Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildImagePreview(imageUrl),
                                ),
                              );
                            }),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descripcionController,
                          label: 'Descripción',
                          icon: Icons.description_outlined,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                    child: const Text('Cancelar',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final data = {
                        'nombre': _nombreController.text.trim(),
                        'precio':
                            double.tryParse(_precioController.text.trim()) ??
                                0.0,
                        'categoria': _categoriaController.text.trim(),
                        'imagen': _imagenController.text.trim(),
                        'descripcion': _descripcionController.text.trim(),
                        'esDestacado': false,
                        'fechaActualizacion': FieldValue.serverTimestamp(),
                      };

                      try {
                        if (editingDocId == null) {
                          await _productosRef.add(data);
                        } else {
                          await _productosRef.doc(editingDocId).update(data);
                        }
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(editingDocId == null
                                  ? 'Producto creado'
                                  : 'Producto actualizado'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      editingDocId == null
                          ? 'Crear Producto'
                          : 'Guardar Cambios',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.black87), // Fix text color
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildImagePreview(String imageUrl) {
    if (imageUrl.isEmpty) return const SizedBox.shrink();
    final String convertedUrl = _convertirUrlDrive(imageUrl);

    return Image.network(
      convertedUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[100],
        child: const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
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
                    const Text(
                      'Productos',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestiona tu catálogo de productos',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _mostrarFormularioProducto(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nuevo Producto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Buscar productos...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
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
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Grid
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _productosRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No hay productos',
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    );
                  }

                  var docs = snapshot.data!.docs;
                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nombre =
                          data['nombre']?.toString().toLowerCase() ?? '';
                      final categoria =
                          data['categoria']?.toString().toLowerCase() ?? '';
                      return nombre.contains(_searchQuery.toLowerCase()) ||
                          categoria.contains(_searchQuery.toLowerCase());
                    }).toList();
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return _buildProductCard(doc);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nombre = data['nombre'] ?? 'Sin nombre';
    final precio = (data['precio'] as num? ?? 0.0).toStringAsFixed(2);
    final categoria = data['categoria'] ?? 'Sin categoría';
    final imagen = data['imagen'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImagePreview(imagen),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        categoria,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'S/ $precio',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            color: Colors.grey[600],
                            onPressed: () => _mostrarFormularioProducto(doc),
                            tooltip: 'Editar',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: Colors.red[400],
                            onPressed: () => _eliminarProducto(doc.id, nombre),
                            tooltip: 'Eliminar',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
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
}
