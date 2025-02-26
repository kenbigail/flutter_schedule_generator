import 'package:flutter/material.dart';
import 'package:flutter_schedule_generator/models/task.dart';
import 'package:flutter_schedule_generator/service/gemini_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Task> tasks = [];
  bool isLoading = false;
  String scheduleResult = "";
  String? priority;
  final taskController = TextEditingController();
  final durationController = TextEditingController();
  final deadlineController = TextEditingController();

  @override
  void dispose() {
    taskController.dispose();
    durationController.dispose();
    deadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Digiteam Schedule Generator",
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF448AFF)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF448AFF)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputCard(),
            const SizedBox(height: 20),
            Expanded(child: _buildTaskList()),
            const SizedBox(height: 20),
            _buildGenerateButton(),
            const SizedBox(height: 20),
            _buildScheduleResult(),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildInputCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF646464), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(taskController, "Task Name"),
            const SizedBox(height: 10),
            _buildTextField(durationController, "Duration (minutes)",
                isNumber: true),
            const SizedBox(height: 10),
            _buildTextField(deadlineController, "Deadline"),
            const SizedBox(height: 10),
            _buildPriorityDropdown(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addTask,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Add Task",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF448AFF),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF646464), width: 1),
        ),
      ),
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<String>(
      value: priority,
      decoration: InputDecoration(
        labelText: "Priority",
        filled: true,
        fillColor: Colors.white, // Tambahkan ini
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: const ["High", "Medium", "Low"]
          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
          .toList(),
      onChanged: (value) => setState(() => priority = value),
    );
  }

  Widget _buildTaskList() {
    return tasks.isEmpty
        ? const Center(
            child: Text("No tasks added",
                style: TextStyle(color: Colors.grey, fontSize: 16)))
        : ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF646464), width: 1),
                ),
                color: Colors.white,
                child: ListTile(
                  title: Text(task.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "Priority: ${task.priority} | Duration: ${task.duration} min"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => tasks.removeAt(index)),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildGenerateButton() {
    return isLoading
        ? const CircularProgressIndicator(color: Color(0xFF448AFF))
        : ElevatedButton(
            onPressed: _generateSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF448AFF),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Generate Schedule",
                style: TextStyle(fontSize: 16, color: Colors.white)),
          );
  }

  Widget _buildScheduleResult() {
    return scheduleResult.isNotEmpty
        ? Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF646464), width: 1),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: SelectableText(
                    scheduleResult,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          )
        : const SizedBox();
  }

  void _addTask() {
    if (taskController.text.isNotEmpty &&
        durationController.text.isNotEmpty &&
        deadlineController.text.isNotEmpty &&
        priority != null) {
      setState(() {
        scheduleResult = "";
        tasks.add(Task(
          name: taskController.text,
          priority: priority!,
          duration: int.tryParse(durationController.text) ?? 5,
          deadline: deadlineController.text,
        ));
      });
      _clearInputs();
    }
  }

  void _clearInputs() {
    taskController.clear();
    durationController.clear();
    deadlineController.clear();
    setState(() => priority = null);
  }

  Future<void> _generateSchedule() async {
    setState(() => isLoading = true);
    try {
      scheduleResult = await GeminiService().generateSchedule(tasks);
      tasks.clear();
    } catch (e) {
      scheduleResult = "Failed to generate schedule: $e";
    }
    setState(() => isLoading = false);
  }
}
