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
          script = ''
            ${pkgs.tgt}/bin/tgtadm --lld iscsi --op new --mode target --tid ${builtins.toString target.index} -T ${target.name}
            ${pkgs.tgt}/bin/tgtadm --lld iscsi --op new --mode logicalunit --tid ${builtins.toString target.index} --lun 1 -b ${target.backingStore}
            ${pkgs.tgt}/bin/tgtadm --lld iscsi --op bind --mode target --tid ${builtins.toString target.index} -I ALL # gives everybody access
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
        serviceConfig = {
          ExecStart = "${pkgs.tgt}/bin/tgtd -f --iscsi nop_interval=30 --iscsi nop_count=10";
          ExecStop = "${pkgs.coreutils}/bin/sleep 30 ; ${pkgs.tgt}/bin/tgtadm --op delete --mode system";
          KillMode = "process";
          Restart = "on-success";
        };
      };
    in
     mkIf config.services.tgtd.enable {
      systemd.services = LUNs // { tgtd = tgtd; };
    };
}
