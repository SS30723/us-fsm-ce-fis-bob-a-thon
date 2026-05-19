# Bob-a-thon Setup Guide

This guide will help you fork and clone the workshop repository to get started with the labs.

---

## Prerequisites

Before starting, ensure you have completed the [Prerequisites](../PREREQUISITES.md) checklist.

**Required:**
- Git installed and configured
- Bob IDE installed
- GitHub account (or access to your organization's Git platform)
- Repository URL (provided by your instructor)

---

## Step 1: Fork the Repository

Your instructor will provide you with the repository URL for this workshop.

### Option A: GitHub/GitHub Enterprise

1. Navigate to the repository URL provided by your instructor
2. Click the **Fork** button in the top-right corner
3. Select your account or organization as the destination
4. Wait for the fork to complete

### Option B: GitLab/Other Git Platforms

Follow your platform's forking process. Consult your instructor if you need assistance.

---

## Step 2: Create a Personal Access Token (Private Repositories Only)

**Skip this step if your instructor told you the repository is public.**

If the repository is private, you'll need a Personal Access Token (PAT) to authenticate when cloning and pushing changes.

### 2a. Create the PAT on GitHub

1. Go to your GitHub tokens page:
   - **GitHub.com**: `https://github.com/settings/tokens`
   - **GitHub Enterprise**: `https://github.ibm.com/settings/tokens` (or your organization's URL)
   - Your instructor will tell you which to use

2. Click **Generate new token → Generate new token (classic)**

3. Configure the token:
   - **Note:** `bob-a-thon workshop`
   - **Expiration:** 7 or 30 days is fine
   - **Select scopes:** check only **`repo`** (this grants full control of private repositories)

4. Click **Generate token** at the bottom

5. **Copy the token immediately** — GitHub won't show it to you again
   - Save it in a secure location (password manager recommended)
   - You'll use this token in place of your password when cloning

### 2b. Understanding PAT Usage

When cloning or pushing to a private repository, Git will prompt for credentials:
- **Username:** Your GitHub username
- **Password:** Paste your PAT (not your actual GitHub password)

Alternatively, you can embed the PAT in the clone URL (see Step 3 below).

---

## Step 3: Clone Your Fork

Once you've forked the repository, clone it to your local machine:

### For Public Repositories

```bash
# Replace <YOUR_USERNAME> with your actual GitHub username
git clone https://github.com/<YOUR_USERNAME>/us-fsm-ce-fis-bob-a-thon.git

# Navigate into the repository
cd us-fsm-ce-fis-bob-a-thon
```

### For Private Repositories

**Option A: Clone with PAT embedded in URL**
```bash
# Replace <YOUR_PAT> and <YOUR_USERNAME> with your actual values
git clone https://<YOUR_PAT>@github.com/<YOUR_USERNAME>/us-fsm-ce-fis-bob-a-thon.git

# Navigate into the repository
cd us-fsm-ce-fis-bob-a-thon
```

**Option B: Clone normally and enter PAT when prompted**
```bash
# Clone the repository
git clone https://github.com/<YOUR_USERNAME>/us-fsm-ce-fis-bob-a-thon.git

# Git will prompt for credentials:
# Username: <your-github-username>
# Password: <paste-your-PAT-here>

# Navigate into the repository
cd us-fsm-ce-fis-bob-a-thon
```

**Option C: Using SSH (if you have SSH keys configured)**
```bash
git clone git@github.com:<YOUR_USERNAME>/us-fsm-ce-fis-bob-a-thon.git

# Navigate into the repository
cd us-fsm-ce-fis-bob-a-thon
```

---

## Step 4: Verify Your Setup

Confirm everything is working:

```bash
# Check you're in the right directory
pwd
# Should show: /path/to/us-fsm-ce-fis-bob-a-thon

# Verify Git is configured
git remote -v
# Should show your fork as 'origin'

# Check the repository structure
ls -la
# Should see: labs/, order-service/, Jenkinsfile, README.md, etc.
```

---

## Step 5: Open in Bob IDE

1. Launch Bob IDE
2. Open the cloned repository:
   - **File → Open Folder** (or **File → Open** on macOS)
   - Navigate to the `us-fsm-ce-fis-bob-a-thon` directory
   - Click **Open** or **Select Folder**

3. Verify Bob can see the repository files in the Explorer sidebar

---

## Step 6: Configure Git (If Needed)

If this is your first time using Git on this machine, configure your identity:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## Next Steps

### For All Participants

**Start with the Intro Labs** to learn Bob fundamentals:
- [Lab 1: Bob Fundamentals](intro-labs/bob-lab-1-fundamentals.md)
- [Lab 2: Bob Advanced Features](intro-labs/bob-lab-2-advanced-features.md)

### After Intro Labs

Choose your track:

**SRE Track:**
- Complete [SRE Setup](sre/00_SETUP.md) to configure Jenkins and create your working branch
- Then proceed with [SRE Lab 1](sre/lab1/LAB1_PR_REVIEW.md)

**App Track:**
- Proceed directly to [App Lab 1](app/lab1/LAB1_CODE_REVIEW.md)

---

## Troubleshooting

### Issue: "Permission denied" when cloning

**Solution:** Verify your Git credentials or SSH keys are configured correctly. Contact your instructor for repository access.

### Issue: "Repository not found"

**Solution:** Double-check the repository URL provided by your instructor. Ensure you have access to the repository.

### Issue: Git asks for username/password repeatedly

**Solution:** Consider using SSH keys or caching your credentials:
```bash
# Cache credentials for 1 hour
git config --global credential.helper 'cache --timeout=3600'
```

### Issue: Can't see files in Bob IDE

**Solution:** Ensure you opened the repository root directory (`us-fsm-ce-fis-bob-a-thon`), not a subdirectory.

---

## Additional Resources

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Forking Guide](https://docs.github.com/en/get-started/quickstart/fork-a-repo)
- [Bob IDE Documentation](https://bob.ibm.com/docs/ide)

---

**Ready to start?** Head to the [Intro Labs](intro-labs/bob-lab-1-fundamentals.md) to begin your Bob journey! 🚀