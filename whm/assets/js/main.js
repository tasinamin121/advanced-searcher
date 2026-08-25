// Advanced Searcher - WHM Plugin JavaScript

(function() {
    'use strict';

    // DOM Elements
    const searchForm = document.querySelector('.search-form');
    const searchInput = document.querySelector('.search-input');
    const searchTypeSelect = document.querySelector('.search-type-select');
    const searchButton = document.querySelector('.search-button');

    // Initialize
    document.addEventListener('DOMContentLoaded', function() {
        initializeAutocomplete();
        initializeFormHandlers();
        initializeKeyboardShortcuts();
    });

    // Autocomplete functionality
    function initializeAutocomplete() {
        if (!searchInput) return;

        let autocompleteTimeout;
        const autocompleteResults = document.createElement('div');
        autocompleteResults.className = 'autocomplete-results';
        autocompleteResults.style.display = 'none';
        autocompleteResults.style.position = 'absolute';
        autocompleteResults.style.background = 'white';
        autocompleteResults.style.border = '1px solid #e0e0e0';
        autocompleteResults.style.borderRadius = '6px';
        autocompleteResults.style.maxHeight = '200px';
        autocompleteResults.style.overflowY = 'auto';
        autocompleteResults.style.width = '100%';
        autocompleteResults.style.zIndex = '1000';
        autocompleteResults.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)';

        searchInput.parentNode.style.position = 'relative';
        searchInput.parentNode.appendChild(autocompleteResults);

        searchInput.addEventListener('input', function() {
            clearTimeout(autocompleteTimeout);
            const query = this.value.trim();
            const searchType = searchTypeSelect ? searchTypeSelect.value : 'domain';

            if (query.length < 2) {
                autocompleteResults.style.display = 'none';
                return;
            }

            autocompleteTimeout = setTimeout(function() {
                fetchAutocompleteSuggestions(query, searchType);
            }, 300);
        });

        searchInput.addEventListener('blur', function() {
            setTimeout(function() {
                autocompleteResults.style.display = 'none';
            }, 200);
        });

        function fetchAutocompleteSuggestions(query, searchType) {
            // Get the current script path to determine API location
            const scriptPath = window.location.pathname;
            const basePath = scriptPath.substring(0, scriptPath.lastIndexOf('/'));
            const apiUrl = basePath + '/api.cgi';
            
            const formData = new FormData();
            formData.append('action', 'autocomplete');
            formData.append('query', query);
            formData.append('search_type', searchType);

            fetch(apiUrl, {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success && data.data && data.data.length > 0) {
                    displayAutocompleteResults(data.data);
                } else {
                    autocompleteResults.style.display = 'none';
                }
            })
            .catch(error => {
                console.error('Autocomplete error:', error);
                autocompleteResults.style.display = 'none';
            });
        }

        function displayAutocompleteResults(suggestions) {
            autocompleteResults.innerHTML = '';
            
            suggestions.forEach(function(suggestion) {
                const item = document.createElement('div');
                item.className = 'autocomplete-item';
                item.style.padding = '10px 15px';
                item.style.cursor = 'pointer';
                item.style.borderBottom = '1px solid #f0f0f0';
                item.textContent = suggestion.label || suggestion.value;

                item.addEventListener('mouseover', function() {
                    this.style.background = '#f5f5f5';
                });

                item.addEventListener('mouseout', function() {
                    this.style.background = 'white';
                });

                item.addEventListener('click', function() {
                    searchInput.value = suggestion.value;
                    autocompleteResults.style.display = 'none';
                    if (searchForm) {
                        searchForm.submit();
                    }
                });

                autocompleteResults.appendChild(item);
            });

            autocompleteResults.style.display = 'block';
        }
    }

    // Form handlers
    function initializeFormHandlers() {
        if (!searchForm) return;

        searchForm.addEventListener('submit', function(e) {
            const query = searchInput.value.trim();
            
            if (!query) {
                e.preventDefault();
                alert('Please enter a search term');
                return;
            }

            // Show loading state
            if (searchButton) {
                searchButton.disabled = true;
                searchButton.textContent = 'Searching...';
            }
        });

        // Handle search type change
        if (searchTypeSelect) {
            searchTypeSelect.addEventListener('change', function() {
                // Update placeholder based on search type
                const placeholders = {
                    'domain': 'Enter domain (e.g., example.com)',
                    'username': 'Enter username (e.g., client01)',
                    'account': 'Enter account name',
                    'reseller': 'Enter reseller name',
                    'package': 'Enter package name',
                    'ip': 'Enter IP address (e.g., 192.168.1.1)'
                };

                if (searchInput) {
                    searchInput.placeholder = placeholders[this.value] || 'Enter search term...';
                }
            });
        }
    }

    // Keyboard shortcuts
    function initializeKeyboardShortcuts() {
        document.addEventListener('keydown', function(e) {
            // Focus search input on '/' key
            if (e.key === '/' && searchInput && document.activeElement !== searchInput) {
                e.preventDefault();
                searchInput.focus();
            }

            // Submit form on Enter when in search input
            if (e.key === 'Enter' && document.activeElement === searchInput && searchForm) {
                e.preventDefault();
                searchForm.submit();
            }
        });
    }

    // Diagnostics function
    window.runDiagnostics = function() {
        // Get the current script path to determine API location
        const scriptPath = window.location.pathname;
        const basePath = scriptPath.substring(0, scriptPath.lastIndexOf('/'));
        const apiUrl = basePath + '/api.cgi';
        
        const formData = new FormData();
        formData.append('action', 'diagnostics');

        const button = document.querySelector('.action-button');
        if (button) {
            button.disabled = true;
            button.textContent = 'Running...';
        }

        fetch(apiUrl, {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success && data.data) {
                updateDiagnosticsDisplay(data.data);
            } else {
                alert('Failed to run diagnostics: ' + (data.message || 'Unknown error'));
            }
        })
        .catch(error => {
            console.error('Diagnostics error:', error);
            alert('Failed to run diagnostics: ' + error.message);
        })
        .finally(function() {
            if (button) {
                button.disabled = false;
                button.textContent = 'Run Diagnostics';
            }
        });
    };

    function updateDiagnosticsDisplay(diagnosticsData) {
        const diagnosticsGrid = document.querySelector('.diagnostics-grid');
        if (!diagnosticsGrid) return;

        diagnosticsGrid.innerHTML = '';

        for (const [key, value] of Object.entries(diagnosticsData)) {
            const item = document.createElement('div');
            item.className = 'diagnostic-item';
            
            const label = document.createElement('span');
            label.className = 'label';
            label.textContent = formatLabel(key);
            
            const valueSpan = document.createElement('span');
            valueSpan.className = 'value';
            valueSpan.textContent = value;
            
            item.appendChild(label);
            item.appendChild(valueSpan);
            diagnosticsGrid.appendChild(item);
        }
    }

    function formatLabel(key) {
        // Convert snake_case or camelCase to Title Case
        return key
            .replace(/_/g, ' ')
            .replace(/([A-Z])/g, ' $1')
            .replace(/\b\w/g, l => l.toUpperCase())
            .trim();
    }

    // Utility function to normalize search input
    window.normalizeSearchInput = function(input, type) {
        if (!input) return '';

        input = input.trim().toLowerCase();

        // Remove www prefix for domains
        if (type === 'domain') {
            input = input.replace(/^www\./, '');
            // Remove trailing dot
            input = input.replace(/\.$/, '');
        }

        return input;
    };

    // Show/hide loading indicator
    window.setLoadingState = function(isLoading) {
        const searchButton = document.querySelector('.search-button');
        if (searchButton) {
            searchButton.disabled = isLoading;
            searchButton.textContent = isLoading ? 'Searching...' : 'Search';
        }
    };

    // Error handling
    window.handleSearchError = function(error) {
        console.error('Search error:', error);
        alert('An error occurred during search. Please try again.');
        setLoadingState(false);
    };

})();