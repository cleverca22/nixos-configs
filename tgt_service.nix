{ config, lib, pkgs, ... }:

with lib;

let
  targetOpts = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
      };
      backingStore = mkOption {
        type = types.str;
      };
      index = mkOption {
        type = types.int;
        description = "the index of the target, must be unique within the server";
      };
      blockSize = mkOption {
        type = types.int;
        default = 512;
      };
    };
    config = {
      name = mkDefault name;
    };
  };
      makeService = target: {
        name = target.name;
        value = {
          description = target.name+" auto-starter";
          wantedBy = [ "basic.target" ];
          partOf = [ "tgtd.service" ];
          path = [ pkgs.tgt ];
          script = let
            tid = toString target.index;
          in ''
            tgtadm --lld iscsi --op new    --mode target      --tid ${tid} -T ${target.name}
            tgtadm --lld iscsi --op new    --mode logicalunit --tid ${tid} --lun 1 -b ${target.backingStore} --bstype=aio --blocksize ${toString target.blockSize}
            tgtadm --lld iscsi --op update --mode logicalunit --tid ${tid} --lun 1 --params thin_provisioning=0
            tgtadm --lld iscsi --op update --mode target      --tid ${tid} -n nop_count -v 5
            tgtadm --lld iscsi --op update --mode target      --tid ${tid} -n nop_interval -v 5
            tgtadm --lld iscsi --op bind   --mode target      --tid ${tid} -I ALL # gives everybody access
          '';
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStop = "${pkgs.tgt}/bin/tgtadm --lld iscsi --op delete --mode target --tid ${builtins.toString target.index}";
          };
        };
      };
in
{
  options = {
    services.tgtd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "enable tgtd running on startup";
      };
      targets = mkOption {
        default = [];
        type = types.loaOf (types.submodule targetOpts);
      };
    };
  };
  config = let
      LUNs = builtins.listToAttrs (map makeService (attrValues config.services.tgtd.targets));
      tgtd = {
        description = "tgtd daemon";
        wantedBy = [ "basic.target" ];
        path = [ pkgs.tgt ];
        script = ''
          exec tgtd -f --iscsi nop_interval=30 --iscsi nop_count=10
        '';
        serviceConfig = {
          ExecStop = "${pkgs.coreutils}/bin/sleep 30 ; ${pkgs.tgt}/bin/tgtadm --op delete --mode system";
          KillMode = "process";
          Restart = "on-success";
        };
      };
    in
     mkIf config.services.tgtd.enable {
      systemd.services = LUNs // { inherit tgtd; };
    };
}
