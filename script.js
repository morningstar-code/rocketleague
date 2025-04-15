// General UI update handler for the game (score, timer, goals, MVP, leaderboard)
window.addEventListener('message', function (event) {

    // Handle score update for both teams
    if (event.data.type === 'updateScore') {
        if (event.data.teamIndex == 1) {
            document.getElementById("teamA_score").innerText = event.data.score;
        } else if (event.data.teamIndex == 2) {
            document.getElementById("teamB_score").innerText = event.data.score;
        }
    }

    // Handle match timer updates and display the countdown
    if (event.data.type === 'updateTimer') {
        let minutes = Math.floor(event.data.timeLeft / 60);
        let seconds = event.data.timeLeft % 60;
        document.getElementById("matchTimer").innerText = `${minutes}:${seconds < 10 ? '0' + seconds : seconds}`;
    }

    // Goal notification (after each goal is scored)
    if (event.data.type === 'goalNotification') {
        let teamName = event.data.teamIndex === 1 ? "Team A" : "Team B";
        let goalMessage = `${teamName} Scored!`;
        document.getElementById("goalMessage").innerText = goalMessage;
        document.getElementById("goalNotification").style.display = "block";

        // Fade out the goal notification after a set time
        setTimeout(function () {
            document.getElementById("goalNotification").style.transition = "opacity 1s";
            document.getElementById("goalNotification").style.opacity = "0"; // Fades out
            setTimeout(function () {
                document.getElementById("goalNotification").style.display = "none";
                document.getElementById("goalNotification").style.opacity = "1"; // Reset opacity for next use
            }, 1000); // Wait for fade effect to finish
        }, 3000);
    }

    // Handle MVP display after the match ends
    if (event.data.type === 'showMVP') {
        const mvpName = event.data.mvpName;
        document.getElementById("mvpMessage").innerText = `MVP: ${mvpName}`;
        document.getElementById("mvpSection").style.display = "block";

        // Fade out MVP message after a set time
        setTimeout(function () {
            document.getElementById("mvpSection").style.transition = "opacity 1s";
            document.getElementById("mvpSection").style.opacity = "0"; // Fades out
            setTimeout(function () {
                document.getElementById("mvpSection").style.display = "none";
                document.getElementById("mvpSection").style.opacity = "1"; // Reset opacity for next use
            }, 1000); // Wait for fade effect to finish
        }, 5000);
    }

    // Handle leaderboard updates and display
    if (event.data.type === 'updateLeaderboard') {
        let leaderboardList = document.getElementById("leaderboardList");
        leaderboardList.innerHTML = ""; // Clear existing leaderboard data

        // Populate the leaderboard with player names and stats
        event.data.players.forEach(function (player) {
            let listItem = document.createElement("li");
            listItem.innerHTML = `
                <span class="player-name">${player.player_name}</span>
                <div class="stats">
                    Wins: ${player.wins} | Goals: ${player.goals}
                </div>
            `;
            leaderboardList.appendChild(listItem);
        });

        document.getElementById("leaderboard").style.display = "block";

        // Hide the leaderboard after 5 seconds
        setTimeout(function () {
            document.getElementById("leaderboard").style.transition = "opacity 1s";
            document.getElementById("leaderboard").style.opacity = "0"; // Fades out
            setTimeout(function () {
                document.getElementById("leaderboard").style.display = "none";
                document.getElementById("leaderboard").style.opacity = "1"; // Reset opacity for next use
            }, 1000); // Wait for fade effect to finish
        }, 5000); // Adjust this timeout based on the duration you want the leaderboard visible
    }

    // Handle the countdown timer on game start
    if (event.data.type === 'startCountdown') {
        let countdownTime = event.data.countdownTime; // From Lua (3, 2, 1, etc.)
        let countdownDisplay = document.getElementById("countdown");
        countdownDisplay.innerText = countdownTime;

        // Countdown loop
        let countdownInterval = setInterval(function () {
            countdownTime--;
            countdownDisplay.innerText = countdownTime;

            // When countdown reaches 0, start the game
            if (countdownTime <= 0) {
                clearInterval(countdownInterval);
                document.getElementById("countdown").style.display = "none"; // Hide countdown
                SendNUIMessage({
                    type: "startGame" // Custom event to trigger game logic
                });
            }
        }, 1000);
    }

    // Handle match start
    if (event.data.type === 'startGame') {
        // Change button or UI elements to indicate match has started
        document.getElementById("startGameButton").innerText = "Game In Progress...";
        document.getElementById("startGameButton").disabled = true;
    }
});

// Event listener for closing the leaderboard manually
document.getElementById("closeLeaderboardButton").addEventListener("click", function () {
    fetch(`https://${GetParentResourceName()}/closeLeaderboard`, {
        method: "POST"
    });
});

// Handling player interaction with the arcade (for viewing the leaderboard)
Citizen.CreateThread(function () {
    exports["rd-interact"]:AddPeekEntryByModel(-668163313, {
        {
            id = "rocketleague_view_leaderboard",
            label = "📊 View Leaderboard",
            icon = "list",
            event = "rocketleague:showLeaderboard",
            parameters = {},
            isEnabled = function () {
                return true;
            }
        }
    }, {
        distance: { radius = 2.5 }
    })
});

// Toggle scoreboard visibility
function toggleScoreboard(visible) {
    const scoreboard = document.getElementById("scoreboard");
    if (visible) {
        scoreboard.style.display = "flex";
    } else {
        scoreboard.style.display = "none";
    }
}

// Update team scores dynamically
function updateTeamScore(teamIndex, score) {
    if (teamIndex == 1) {
        document.getElementById("teamA_score").innerText = score;
    } else if (teamIndex == 2) {
        document.getElementById("teamB_score").innerText = score;
    }
}

// Update match timer dynamically
function updateMatchTimer(timeLeft) {
    let minutes = Math.floor(timeLeft / 60);
    let seconds = timeLeft % 60;
    document.getElementById("matchTimer").innerText = `${minutes}:${seconds < 10 ? '0' + seconds : seconds}`;
}

// Update goal notification
function updateGoalNotification(teamIndex) {
    let teamName = teamIndex === 1 ? "Team A" : "Team B";
    let goalMessage = `${teamName} Scored!`;
    document.getElementById("goalMessage").innerText = goalMessage;
    document.getElementById("goalNotification").style.display = "block";
    setTimeout(function () {
        document.getElementById("goalNotification").style.display = "none";
    }, 3000);
}

// Leaderboard display functionality
function displayLeaderboard(players) {
    let leaderboardList = document.getElementById("leaderboardList");
    leaderboardList.innerHTML = ""; // Clear existing leaderboard

    players.forEach(function (player) {
        let listItem = document.createElement("li");
        listItem.innerHTML = `
            <span class="player-name">${player.player_name}</span>
            <div class="stats">
                Wins: ${player.wins} | Goals: ${player.goals}
            </div>
        `;
        leaderboardList.appendChild(listItem);
    });

    document.getElementById("leaderboard").style.display = "block";
    setTimeout(function () {
        document.getElementById("leaderboard").style.display = "none";
    }, 5000); // Auto-hide leaderboard
}

// Adjust UI when the match is over
function showMatchOver(result) {
    if (result === "timeout") {
        document.getElementById("matchResult").innerText = "Match Ended: Timeout!";
    } else {
        document.getElementById("matchResult").innerText = `Match Ended: ${result}`;
    }
    document.getElementById("matchOverSection").style.display = "block";
    setTimeout(function () {
        document.getElementById("matchOverSection").style.display = "none";
    }, 5000);
}

// Show MVP of the match
function showMVP(mvpName) {
    document.getElementById("mvpMessage").innerText = `MVP: ${mvpName}`;
    document.getElementById("mvpSection").style.display = "block";
    setTimeout(function () {
        document.getElementById("mvpSection").style.display = "none";
    }, 5000);
}

// Handle custom actions for the start of the match
function startMatchActions() {
    const startButton = document.getElementById("startButton");
    startButton.innerText = "Game In Progress";
    startButton.disabled = true;
}

// Handle display of the countdown timer for match start
function startCountdown(countdownTime) {
    const countdownDisplay = document.getElementById("countdown");
    countdownDisplay.innerText = countdownTime;

    let countdownInterval = setInterval(function () {
        countdownTime--;
        countdownDisplay.innerText = countdownTime;

        if (countdownTime <= 0) {
            clearInterval(countdownInterval);
            document.getElementById("countdown").style.display = "none";
            // Trigger game start
            SendNUIMessage({
                type: "startGame"
            });
        }
    }, 1000);
}

// Adding the leaderboard close button functionality
function addLeaderboardCloseButton() {
    const closeButton = document.createElement("button");
    closeButton.innerText = "Close Leaderboard";
    closeButton.onclick = function () {
        document.getElementById("leaderboard").style.display = "none";
    };
    document.getElementById("leaderboard").appendChild(closeButton);
}
function startGameClicked() {
    fetch(`https://${GetParentResourceName()}/startGameClicked`, {
        method: "POST"
    });
}
window.addEventListener('message', function (event) {
    if (event.data.type === 'updateCountdown') {
        document.getElementById("countdown").innerText = event.data.countdownTime;
    }

    if (event.data.type === 'startGame') {
        // Start the game: Hide countdown and show game screen
        document.getElementById("countdown").style.display = "none";
        document.getElementById("gameScreen").style.display = "block";
    }
});
window.addEventListener('message', function (event) {
    if (event.data.type === 'updateScore') {
        if (event.data.teamIndex == 1) {
            document.getElementById("teamA_score").innerText = `Team A: ${event.data.score}`;
        } else if (event.data.teamIndex == 2) {
            document.getElementById("teamB_score").innerText = `Team B: ${event.data.score}`;
        }
    }
});
window.addEventListener('message', function (event) {
    if (event.data.type === 'goalNotification') {
        let teamName = event.data.teamIndex === 1 ? "Team A" : "Team B";
        document.getElementById("goalNotification").innerText = `${teamName} Scored!`;
        document.getElementById("goalNotification").style.display = "block";
        setTimeout(function () {
            document.getElementById("goalNotification").style.display = "none";
        }, 3000);  // Hide the notification after 3 seconds
    }
});
function startGameClicked() {
    fetch(`https://${GetParentResourceName()}/startGameClicked`, {
        method: "POST"
    });
    
    // Hide the start button after clicking it
    document.getElementById("startGameButton").style.display = "none";

    // Optionally, show the countdown or game screen here
    document.getElementById("gameScreen").style.display = "block";
}
