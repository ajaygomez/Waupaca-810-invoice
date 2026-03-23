# Claude Instructions

## RPGLE Program Changes - REQUIRED Steps

When making changes to any RPGLE program (.rpgle, .sqlrpgle files), you MUST:

1. **Line Length Check**: Ensure all lines are 80 characters or less
   - Use `awk 'length > 80 {print NR": "length" chars"}' <file>` to find violations
   - Break long lines appropriately (SQL can span multiple lines, comments can be split)

2. **Compile the Program**: Use the `ibmi-compile` skill to verify no compilation errors
   - Run: `/ibmi-compile <path-to-source>`
   - Example: `/ibmi-compile qrpglesrc/edi027.sqlrpgle`
   - Do not consider the change complete until compilation succeeds

When creating plans, don't give me any timelines unless I ask.


### Project Structure
- `angular/` - Angular frontend application
- `express/` - Express.js backend API
- `qrpglesrc/` - IBM i RPGLE programs
