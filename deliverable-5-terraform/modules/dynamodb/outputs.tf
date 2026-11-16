output "idempotency_table_name" {
  description = "Idempotency keys table name"
  value       = aws_dynamodb_table.idempotency_keys.name
}

output "sessions_table_name" {
  description = "Sessions table name"
  value       = aws_dynamodb_table.sessions.name
}

output "transaction_state_table_name" {
  description = "Transaction state table name"
  value       = aws_dynamodb_table.transaction_state.name
}