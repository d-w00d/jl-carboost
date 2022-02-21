let progressBar = document.querySelector(".prog");
let boostpercent = document.getElementById("boosting-progress");
let boosting = document.querySelector("#boosting-app");
let isJoined = false;
let queueButton = document.querySelector(".join-queue");
let mycontractbutton = document.querySelector(".my-contract");
let buycontractbutton = document.querySelector(".buy-contract");
let contractPage = document.getElementById("boosting-contract");
let shopPage = document.getElementById("boosting-shop");

$(document).ready(function () {
  loadBoostData();
  boostingheader = boosting.querySelector("header");
  boostingheader.addEventListener("mousedown", () => {
    boostingheader.classList.add("active");
    boostingheader.addEventListener("mousemove", onDrag);
  });
  document.addEventListener("mouseup", (e) => {
    boostingheader.classList.remove("active");
    boostingheader.removeEventListener("mousemove", onDrag);
  });

  queueButton.onclick = () => {
    toggleQueue();
  };

  mycontractbutton.onclick = () => {
    if (!shopPage.classList.contains("hidden")) {
      shopPage.classList.add("hidden");
      contractPage.classList.remove("hidden");
    }
  };
  buycontractbutton.onclick = () => {
    // console.log("TEST");
    if (!contractPage.classList.contains("hidden")) {
      contractPage.classList.add("hidden");
      shopPage.classList.remove("hidden");
    }
  };
});

function toggleQueue() {
  const loadingicon = document.createElement("i");
  loadingicon.className = "fas fa-rotate fa-spin";
  loadingicon.style.fontSize = "15px";
  if (queueButton.textContent == "Join Queue") {
    queueButton.textContent = "";
    queueButton.appendChild(loadingicon);
    setTimeout(() => {
      loadingicon.remove();
      queueButton.textContent = "Exit Queue";
      Notification("You have joined the queue", "info");
      $.post(
        "https://jl-carboost/joinqueue",
        JSON.stringify({
          status: true,
        })
      );
    }, 3000);
  } else {
    queueButton.textContent = "";
    queueButton.appendChild(loadingicon);
    setTimeout(() => {
      loadingicon.remove();
      queueButton.textContent = "Join Queue";
      Notification("You have left the queue", "info");
      $.post(
        "https://jl-carboost/joinqueue",
        JSON.stringify({
          status: false,
        })
      );
    }, 3000);
  }
}

function boostProgress(currentVal, toVal) {
  // console.log(currentVal, toVal);
  if (toVal === 0) {
    return (boostpercent.style.width = 0 + "%");
  } else {
    let progBar = setInterval(() => {
      currentVal++;
      boostpercent.style.width = currentVal + "%";
      if (currentVal == toVal) {
        clearInterval(progBar);
      }
    }, 100);
  }
}

function loadBoostData() {
  let boostingList = document.querySelector("#boosting-contract");
  let noContractTitle = boostingList.getElementsByClassName("title");
  fetch("https://jl-carboost/setupboostapp", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({}),
  }).then((resp) =>
    resp.json().then((resp) => {
      const data = resp.boostdata;
      const contract = data.contract;
      const title = document.querySelector("#no-contract");
      if (contract) {
        if (!title.classList.contains("hidden")) title.classList.add("hidden");
        for (let i = 0; i < contract.length; i++) {
          const contractdata = contract[i].data;
          const contractParent = document.getElementById("boosting-contract");
          const contractCart = document.createElement("div");
          contractCart.classList.add("boost-contract");
          contractCart.innerHTML = `<div class="boost-text">
          <p id="boost-type">Boost Type: <b>${contractdata.tier}</b></p>
          <p>Owner: ${contractdata.owner}</p>
        </div>
        <div class="boost-info">
          <p>Vehicle Type: <b id="vehicle-type">${contractdata.car}</b></p>
          <p>Expires in: 5 hours</p>
        </div>
        <div class="boost-button">
          <button id="startcontract" class="start">Start Contract</button>
          <button class="transfer">Transfer Contract</button>
          <button class="sell">Sell Contract</button>
        </div>
          `;
          let testing = contractCart.querySelector("#startcontract");
          testing.addEventListener("click", toggleBoosting);
          contractParent.appendChild(contractCart);
          console.log(JSON.stringify(contractdata));
        }
      } else {
        if (!title.classList.contains("hidden")) {
          title.classList.add("hidden");
        }
      }
      let color;
      boostProgress(0, data.xp);
      // console.log(JSON.stringify(data.contract));
    })
  );
}

function toggleBoosting(event) {
  let isStart;

  const buttonClicked = event.target;
  const parent = buttonClicked.parentElement.parentElement;
  if (buttonClicked.innerText === "Start Contract") {
    isStart = false;
  } else {
    isStart = true;
  }
  if (isStart) {
    Notification("Contract Ended", "error");
    buttonClicked.innerText = "Start Contract";
    stopContract(parent);
  } else {
    Notification("Contract Started", "success");
    buttonClicked.innerText = "Stop Contract";
    startContract(parent);
  }
}

function startContract(data) {
  data.id = "uniqueid";
  const boostType = data.querySelector("#boost-type b").innerText;
  const carModel = data.querySelector("#vehicle-type").textContent;
  $.post(
    "https://jl-carboost/startcontract",
    JSON.stringify({ car: carModel, type: boostType })
  );
}

function stopContract(data) {}

function setupNewContract(data) {
  console.log(JSON.stringify(data));
}
