'use strict';

if (process.argv.includes('--self-test')) {
  console.log('example-local self-test ok');
  process.exit(0);
}

let buffer = '';

function writeMessage(message) {
  const body = JSON.stringify(message);
  const length = Buffer.byteLength(body, 'utf8');
  process.stdout.write(`Content-Length: ${length}\r\n\r\n${body}`);
}

function writeResult(id, result) {
  writeMessage({ jsonrpc: '2.0', id, result });
}

function writeError(id, code, message) {
  writeMessage({
    jsonrpc: '2.0',
    id,
    error: { code, message }
  });
}

function handleRequest(message) {
  if (!message || !message.method) {
    return;
  }

  switch (message.method) {
    case 'initialize':
      writeResult(message.id, {
        protocolVersion: '2024-11-05',
        capabilities: {
          tools: {}
        },
        serverInfo: {
          name: 'example-local',
          version: '0.1.0'
        }
      });
      return;
    case 'notifications/initialized':
      return;
    case 'tools/list':
      writeResult(message.id, {
        tools: [
          {
            name: 'workspace.inspect',
            description: 'Return a simple confirmation that the example MCP server is running.',
            inputSchema: {
              type: 'object',
              properties: {
                path: {
                  type: 'string',
                  description: 'Optional path to echo in the response.'
                }
              },
              additionalProperties: false
            }
          }
        ]
      });
      return;
    case 'tools/call': {
      const toolName = message.params && message.params.name;
      if (toolName !== 'workspace.inspect') {
        writeError(message.id, -32601, `Unsupported tool: ${toolName}`);
        return;
      }

      const pathValue = message.params && message.params.arguments && message.params.arguments.path;
      const suffix = pathValue ? ` (${pathValue})` : '';
      writeResult(message.id, {
        content: [
          {
            type: 'text',
            text: `example-local server is running${suffix}`
          }
        ],
        isError: false
      });
      return;
    }
    default:
      writeError(message.id, -32601, `Unsupported method: ${message.method}`);
  }
}

function tryReadMessages() {
  while (true) {
    const headerEnd = buffer.indexOf('\r\n\r\n');
    if (headerEnd < 0) {
      return;
    }

    const headerText = buffer.slice(0, headerEnd);
    const lengthMatch = headerText.match(/Content-Length:\s*(\d+)/i);
    if (!lengthMatch) {
      buffer = '';
      return;
    }

    const bodyLength = Number.parseInt(lengthMatch[1], 10);
    const messageStart = headerEnd + 4;
    if (buffer.length < messageStart + bodyLength) {
      return;
    }

    const body = buffer.slice(messageStart, messageStart + bodyLength);
    buffer = buffer.slice(messageStart + bodyLength);

    let parsed;
    try {
      parsed = JSON.parse(body);
    } catch (error) {
      writeError(null, -32700, `Invalid JSON payload: ${error.message}`);
      continue;
    }

    handleRequest(parsed);
  }
}

process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => {
  buffer += chunk;
  tryReadMessages();
});
