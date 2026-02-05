import 'pipeline_step.dart';

class PipelineRunner {
  // The PipelineRunner is a utility class that provides a static method to run a series of pipeline steps. It takes a context and a list of steps, and executes each step in order, passing the same context to each step. If any step throws an error, it catches the error, logs it, and continues with the next steps.
  static Future<void> run<T>(T ctx, List<PipelineStep<T>> steps) async {
    // The PipelineRunner is responsible for executing a series of steps in order, passing the same context to each step. It ensures that each step is executed sequentially and handles any errors that may occur during the execution of the steps.
    for (final step in steps) {
      try{
        // even if one step fails, we catch the error and continue with the next steps, ensuring that the pipeline continues to run without interruption.
        await step.execute(ctx);
      }catch(e){
        // Log the error and continue with the next step
        print("Error executing step ${step.runtimeType}: $e");
        // Depending on the use case, you might want to implement more sophisticated error handling here, such as retrying the step, sending an alert, or recording the error in a monitoring system.
        break;
      }
    }
  }
}