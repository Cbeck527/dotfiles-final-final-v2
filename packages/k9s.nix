{ config, ... }:

{
  programs.k9s = {
    enable = true;
    aliases = {
      dp = "deployments";
      sec = "v1/secrets";
      jo = "jobs";
      cr = "clusterroles";
      crb = "clusterrolebindings";
      ro = "roles";
      rb = "rolebindings";
      np = "networkpolicies";
    };

    settings = {
      k9s = {
        liveViewAutoRefresh = true;
        screenDumpDir = "${config.home.homeDirectory}/Downloads/k9s-screen-dumps";
        refreshRate = 2;
        maxConnRetry = 5;
        readOnly = false;
        noExitOnCtrlC = false;
        skipLatestRevCheck = false;
        disablePodCounting = false;
        ui = {
          enableMouse = false;
          logoless = true;
          reactive = true;
        };
        shellPod = {
          image = "debian:bookworm-slim";
          namespace = "default";
          limits = {
            cpu = "100m";
            memory = "256Mi";
          };
        };
        imageScans = {
          enable = false;
          exclusions = {
            namespaces = [ ];
            labels = { };
          };
        };
        logger = {
          tail = 100;
          buffer = 5000;
          sinceSeconds = -1;
          textWrap = false;
          showTime = false;
        };
        thresholds = {
          cpu = {
            critical = 90;
            warn = 70;
          };
          memory = {
            critical = 90;
            warn = 70;
          };
        };
      };
    };

    plugins = {
      debug_container = {
        shortCut = "Shift-D";
        description = "Add debug container";
        dangerous = true;
        scopes = [ "containers" ];
        command = "sh";
        background = false;
        confirm = true;
        args = [
          "-c"
          "kubectl --kubeconfig=$KUBECONFIG debug -it -n=$NAMESPACE $POD --target=$NAME --image=nicolaka/netshoot:v0.13 --share-processes -- bash"
        ];
      };
      node-root-shell = {
        shortCut = "Shift-S";
        description = "Run root shell on node";
        dangerous = true;
        scopes = [ "nodes" ];
        command = "bash";
        background = false;
        confirm = true;
        args = [
          "-c"
          ''
            host="$1"
            json='
            {
              "apiVersion": "v1",
              "spec": {
                "hostIPC": true,
                "hostNetwork": true,
                "hostPID": true
            '
            if ! [[ -z "$host" ]]; then
              json+=",
              \"nodeSelector\" : {
                \"kubernetes.io/hostname\" : \"$host\"
              }
              ";
            fi
            json+='
              }
            }
            '
            kubectl run -ti --image ubuntu:latest --rm --privileged --restart=Never --overrides="$json" root --command -- nsenter -t 1 -m -u -n -i -- bash -l
          ''
        ];
      };
      eks-node-viewer = {
        shortCut = "Shift-X";
        description = "eks-node-viewer";
        scopes = [ "node" ];
        background = false;
        command = "sh";
        args = [
          "-c"
          "eks-node-viewer --kubeconfig $KUBECONFIG --resources cpu,memory --extra-labels karpenter.sh/nodepool,eks-node-viewer/node-age --node-sort=creation=dsc"
        ];
      };
    };
  };
}
