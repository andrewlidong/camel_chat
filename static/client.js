// Connect to WebSocket server
const ws = new WebSocket('ws://' + window.location.host + '/ws');

// Handle WebSocket connection
ws.onopen = () => {
    console.log('Connected to chat server');
};

// Handle incoming messages
ws.onmessage = (event) => {
    const messages = document.getElementById('messages');
    const message = document.createElement('div');
    message.textContent = event.data;
    messages.appendChild(message);
    messages.scrollTop = messages.scrollHeight;
};

// Handle input box
const input = document.getElementById('input');
input.addEventListener('keypress', (event) => {
    if (event.key === 'Enter') {
        const message = input.value.trim();
        if (message) {
            ws.send(message);
            input.value = '';
        }
    }
});