const MAX_MESSAGE_LENGTH = 500;

let ws = null;
let username = '';
let isTyping = false;
let typingTimeout = null;
let typingUsers = new Set();

// Format timestamp
function formatTimestamp(timestamp) {
    const date = new Date(parseInt(timestamp) * 1000);
    return date.toLocaleTimeString();
}

// Update character counter
function updateCharCounter(length) {
    const counter = document.getElementById('char-counter');
    counter.textContent = `${length} / ${MAX_MESSAGE_LENGTH}`;

    // Remove previous classes
    counter.classList.remove('warning', 'error');

    // Add visual feedback based on length
    if (length > MAX_MESSAGE_LENGTH) {
        counter.classList.add('error');
    } else if (length > MAX_MESSAGE_LENGTH * 0.8) {
        counter.classList.add('warning');
    }
}

// Update typing indicator
function updateTypingIndicator() {
    const typingIndicator = document.getElementById('typing-indicator');
    if (typingUsers.size > 0) {
        const names = Array.from(typingUsers).join(', ');
        typingIndicator.textContent = `${names} ${typingUsers.size === 1 ? 'is' : 'are'} typing...`;
        typingIndicator.style.display = 'block';
    } else {
        typingIndicator.style.display = 'none';
    }
}

// Handle login
document.getElementById('login-button').addEventListener('click', () => {
    username = document.getElementById('username-input').value.trim();
    if (username) {
        // Connect to WebSocket server with username
        ws = new WebSocket('ws://' + window.location.host + '/ws?username=' + encodeURIComponent(username));

        // Show chat interface
        document.getElementById('login-form').style.display = 'none';
        document.getElementById('chat-container').style.display = 'block';

        // Focus input
        document.getElementById('input').focus();

        setupWebSocket();
    }
});

// Handle WebSocket connection
function setupWebSocket() {
    if (!ws) return;

    ws.onopen = () => {
        console.log('Connected to chat server');
    };

    // Handle incoming messages
    ws.onmessage = (event) => {
        const message = JSON.parse(event.data);

        if (message.type === 'typing_status') {
            if (message.is_typing) {
                typingUsers.add(message.username);
            } else {
                typingUsers.delete(message.username);
            }
            updateTypingIndicator();
            return;
        }

        const messages = document.getElementById('messages');
        const messageDiv = document.createElement('div');
        messageDiv.className = 'message';

        if (message.username === 'System') {
            messageDiv.className += ' system-message';
            messageDiv.textContent = message.message;
        } else {
            const usernameSpan = document.createElement('span');
            usernameSpan.className = 'username';
            usernameSpan.style.color = message.color;
            usernameSpan.textContent = message.username;

            const timestampSpan = document.createElement('span');
            timestampSpan.className = 'timestamp';
            timestampSpan.textContent = formatTimestamp(message.timestamp);

            const messageSpan = document.createElement('span');
            messageSpan.textContent = ': ' + message.message;

            messageDiv.appendChild(usernameSpan);
            messageDiv.appendChild(timestampSpan);
            messageDiv.appendChild(messageSpan);
        }

        messages.appendChild(messageDiv);
        messages.scrollTop = messages.scrollHeight;
    };

    // Handle input box
    const input = document.getElementById('input');
    input.addEventListener('keypress', (event) => {
        if (event.key === 'Enter') {
            const message = input.value.trim();
            if (message) {
                // Check message length
                if (message.length > MAX_MESSAGE_LENGTH) {
                    alert(`Message too long! Maximum ${MAX_MESSAGE_LENGTH} characters allowed.`);
                    return;
                }
                ws.send(message);
                input.value = '';
                updateCharCounter(0);
            }
        }
    });

    // Handle typing indicator and character counter
    input.addEventListener('input', () => {
        // Update character counter
        updateCharCounter(input.value.length);

        if (!isTyping) {
            isTyping = true;
            // Send typing start message
            ws.send(JSON.stringify({ type: 'typing_start' }));
        }

        // Clear previous timeout
        if (typingTimeout) {
            clearTimeout(typingTimeout);
        }

        // Set new timeout
        typingTimeout = setTimeout(() => {
            isTyping = false;
            // Send typing end message
            ws.send(JSON.stringify({ type: 'typing_end' }));
        }, 1000);
    });
}