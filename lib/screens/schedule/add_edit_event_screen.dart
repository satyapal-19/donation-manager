import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/event_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/common_widgets.dart';

class AddEditEventScreen extends StatefulWidget {
  final EventModel? existingEvent;
  final UserModel user;
  final int dayNumber;

  const AddEditEventScreen({
    super.key,
    this.existingEvent,
    required this.user,
    required this.dayNumber,
  });

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _maharajNameController = TextEditingController();
  final _maharajLocationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeController = TextEditingController();
  final _eventService = EventService();

  String _selectedType = AppConstants.eventTypes.first;
  File? _maharajPhoto;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      final e = widget.existingEvent!;
      _titleController.text = e.title;
      _maharajNameController.text = e.maharajName;
      _maharajLocationController.text = e.maharajLocation;
      _descriptionController.text = e.description ?? '';
      _timeController.text = e.time;
      _selectedType = e.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _maharajNameController.dispose();
    _maharajLocationController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (file != null) setState(() => _maharajPhoto = File(file.path));
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time != null) {
      _timeController.text =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final event = EventModel(
        id: widget.existingEvent?.id ?? '',
        dayNumber: widget.dayNumber,
        time: _timeController.text,
        title: _selectedType,
        maharajName: _maharajNameController.text.trim(),
        maharajPhotoUrl: widget.existingEvent?.maharajPhotoUrl,
        maharajLocation: _maharajLocationController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: widget.existingEvent?.createdAt ?? DateTime.now(),
      );

      if (widget.existingEvent != null) {
        await _eventService.updateEvent(event, newMaharajPhoto: _maharajPhoto);
      } else {
        await _eventService.addEvent(event, maharajPhoto: _maharajPhoto);
      }

      if (!mounted) return;
      AppHelpers.showToast(widget.existingEvent != null
          ? 'कार्यक्रम अपडेट केला'
          : 'कार्यक्रम जोडला');
      Navigator.pop(context);
    } catch (e) {
      AppHelpers.showToast('चूक झाली: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OmAppBar(
        title: widget.existingEvent != null
            ? 'कार्यक्रम बदला'
            : 'नवीन कार्यक्रम',
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Day indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppTheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        AppConstants.saptahDays[widget.dayNumber - 1],
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Event type dropdown
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'कार्यक्रम प्रकार *',
                    prefixIcon: Icon(Icons.event, color: AppTheme.primary),
                  ),
                  items: AppConstants.eventTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
                const SizedBox(height: 14),

                // Time picker
                GestureDetector(
                  onTap: _selectTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: 'वेळ *',
                        prefixIcon:
                            Icon(Icons.access_time, color: AppTheme.primary),
                        hintText: 'जसे: 06:00',
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'वेळ आवश्यक आहे' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _maharajNameController,
                  decoration: const InputDecoration(
                    labelText: 'महाराज/कीर्तनकार नाव *',
                    prefixIcon:
                        Icon(Icons.person_outline, color: AppTheme.primary),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'नाव आवश्यक आहे' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _maharajLocationController,
                  decoration: const InputDecoration(
                    labelText: 'गाव/शहर *',
                    prefixIcon:
                        Icon(Icons.location_on_outlined, color: AppTheme.primary),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'स्थान आवश्यक आहे' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'वर्णन (ऐच्छिक)',
                    prefixIcon:
                        Icon(Icons.description_outlined, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 20),

                // Photo picker
                const Text('महाराज फोटो',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3),
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _maharajPhoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_maharajPhoto!,
                                fit: BoxFit.cover,
                                width: double.infinity))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: AppTheme.primary.withOpacity(0.5),
                                  size: 32),
                              const SizedBox(height: 8),
                              Text('फोटो निवडा',
                                  style: TextStyle(
                                      color: AppTheme.primary.withOpacity(0.7))),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                GradientButton(
                  text: widget.existingEvent != null
                      ? 'बदल जतन करा'
                      : 'कार्यक्रम जोडा',
                  icon: Icons.save_outlined,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
