// Enhanced interactivity for Spectrum Loot Tool documentation

document.addEventListener('DOMContentLoaded', function() {
    // Add copy buttons to code blocks
    addCopyButtonsToCodeBlocks();
    
    // Initialize WoW-style tooltips
    initializeWoWTooltips();
    
    // Add interactive command examples
    initializeCommandExamples();
    
    // Initialize feature cards animations
    initializeFeatureAnimations();
});

function addCopyButtonsToCodeBlocks() {
    const codeBlocks = document.querySelectorAll('pre code');
    
    codeBlocks.forEach(function(codeBlock) {
        const pre = codeBlock.parentElement;
        const button = document.createElement('button');
        button.className = 'copy-button';
        button.innerHTML = '<i class="material-icons">content_copy</i>';
        button.setAttribute('title', 'Copy to clipboard');
        
        button.addEventListener('click', function() {
            navigator.clipboard.writeText(codeBlock.textContent).then(function() {
                button.innerHTML = '<i class="material-icons">check</i>';
                button.style.color = '#4caf50';
                
                setTimeout(function() {
                    button.innerHTML = '<i class="material-icons">content_copy</i>';
                    button.style.color = '';
                }, 2000);
            });
        });
        
        pre.style.position = 'relative';
        pre.appendChild(button);
    });
}

function initializeWoWTooltips() {
    const tooltipElements = document.querySelectorAll('[data-wow-tooltip]');
    
    tooltipElements.forEach(function(element) {
        element.addEventListener('mouseenter', function() {
            showWoWTooltip(element);
        });
        
        element.addEventListener('mouseleave', function() {
            hideWoWTooltip();
        });
    });
}

function showWoWTooltip(element) {
    const tooltipContent = element.getAttribute('data-wow-tooltip');
    const tooltip = document.createElement('div');
    tooltip.className = 'wow-tooltip';
    tooltip.innerHTML = tooltipContent;
    tooltip.style.position = 'absolute';
    tooltip.style.zIndex = '1000';
    tooltip.style.pointerEvents = 'none';
    
    document.body.appendChild(tooltip);
    
    element.addEventListener('mousemove', function(e) {
        tooltip.style.left = e.pageX + 10 + 'px';
        tooltip.style.top = e.pageY + 10 + 'px';
    });
}

function hideWoWTooltip() {
    const tooltip = document.querySelector('.wow-tooltip');
    if (tooltip) {
        tooltip.remove();
    }
}

function initializeCommandExamples() {
    const commandExamples = document.querySelectorAll('.command-example');
    
    commandExamples.forEach(function(example) {
        example.addEventListener('click', function() {
            const command = example.querySelector('code').textContent;
            navigator.clipboard.writeText(command).then(function() {
                const originalText = example.innerHTML;
                example.innerHTML = '<i class="material-icons" style="color: #4caf50;">check</i> Copied to clipboard!';
                
                setTimeout(function() {
                    example.innerHTML = originalText;
                }, 1500);
            });
        });
        
        example.style.cursor = 'pointer';
        example.setAttribute('title', 'Click to copy command');
    });
}

function initializeFeatureAnimations() {
    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(function(entry) {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, {
        threshold: 0.1
    });
    
    const featureCards = document.querySelectorAll('.feature-card');
    featureCards.forEach(function(card) {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(card);
    });
}

// Add material icons support if not already loaded
if (!document.querySelector('link[href*="material-icons"]')) {
    const link = document.createElement('link');
    link.href = 'https://fonts.googleapis.com/icon?family=Material+Icons';
    link.rel = 'stylesheet';
    document.head.appendChild(link);
}
