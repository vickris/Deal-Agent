# Deal-Agent

Agent framework that other developers can tap into when building their agents. I chose Elixir for this project because of the benefits BEAM comes with:

 - Isolated processes so each agent run is treated as an independent process and one agent crushing does not affect other agents.
 - Supervision, where we get automatic restarts in the case of unforseen failures.
 - OTP behaviors which provide a consistent structure for long running processes.
 - Message passing making sure tool execution happens cleanly. 


 ## Notable Features
 
 - Comes with telemetry and observability. 
 - Configurable timeouts.
 - Information on token usage.
 - Comes with a context-size guardrail that stops the run before it exceeds the model's context window.
 - Error reporting is part of the trace after a run.

 


